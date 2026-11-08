import { createHash } from 'node:crypto';
import { readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const args = process.argv.slice(2);

function printUsage() {
  console.log(`Usage:
  node supabase/scripts/import_tracks.mjs --template <music-folder> <metadata.csv>
  node supabase/scripts/import_tracks.mjs <music-folder> <metadata.csv>

Import requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in the environment.
`);
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;

  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (quoted) {
      if (char === '"' && text[index + 1] === '"') {
        field += '"';
        index++;
      } else if (char === '"') {
        quoted = false;
      } else {
        field += char;
      }
    } else if (char === '"' && field.length === 0) {
      quoted = true;
    } else if (char === ',') {
      row.push(field);
      field = '';
    } else if (char === '\n' || char === '\r') {
      if (char === '\r' && text[index + 1] === '\n') index++;
      row.push(field);
      if (row.some((value) => value.trim() !== '')) rows.push(row);
      row = [];
      field = '';
    } else {
      field += char;
    }
  }

  if (quoted) throw new Error('CSV contains an unclosed quoted field.');
  row.push(field);
  if (row.some((value) => value.trim() !== '')) rows.push(row);
  if (rows.length === 0) throw new Error('CSV is empty.');

  const headers = rows[0].map((header) => header.trim().replace(/^\uFEFF/, ''));
  if (new Set(headers).size !== headers.length) {
    throw new Error('CSV contains duplicate column names.');
  }
  const required = ['filename', 'title', 'artist'];
  const missing = required.filter((header) => !headers.includes(header));
  if (missing.length) {
    throw new Error(`CSV is missing required columns: ${missing.join(', ')}`);
  }

  return rows.slice(1).map((values, rowIndex) => {
    const record = Object.fromEntries(
      headers.map((header, columnIndex) => [header, (values[columnIndex] ?? '').trim()]),
    );
    if (!record.filename) throw new Error(`CSV row ${rowIndex + 2} has no filename.`);
    return record;
  });
}

function decodeId3Text(bytes) {
  if (bytes.length === 0) return '';
  const encoding = bytes[0];
  const value = bytes.subarray(1);
  try {
    if (encoding === 0) return value.toString('latin1').replace(/\0+$/g, '').trim();
    if (encoding === 3) return value.toString('utf8').replace(/\0+$/g, '').trim();
    if (encoding === 1) {
      let offset = 0;
      if (value[0] === 0xff && value[1] === 0xfe) offset = 2;
      else if (value[0] === 0xfe && value[1] === 0xff) {
        return Buffer.from(value.subarray(2)).swap16().toString('utf16le').replace(/\0+$/g, '').trim();
      }
      return value.subarray(offset).toString('utf16le').replace(/\0+$/g, '').trim();
    }
    if (encoding === 2) {
      const even = value.length - (value.length % 2);
      return Buffer.from(value.subarray(0, even)).swap16().toString('utf16le').replace(/\0+$/g, '').trim();
    }
  } catch (_) {
    return '';
  }
  return '';
}

function readId3(bytes) {
  const metadata = {};
  const pictures = [];

  if (bytes.length >= 10 && bytes.toString('ascii', 0, 3) === 'ID3') {
    const major = bytes[3];
    const tagSize = ((bytes[6] & 0x7f) << 21) |
      ((bytes[7] & 0x7f) << 14) |
      ((bytes[8] & 0x7f) << 7) |
      (bytes[9] & 0x7f);
    let cursor = 10;
    const end = Math.min(bytes.length, cursor + tagSize);

    while (cursor + 10 <= end) {
      const frameId = bytes.toString('ascii', cursor, cursor + 4);
      if (!/^[A-Z0-9]{4}$/.test(frameId)) break;
      const frameSize = major === 4
        ? ((bytes[cursor + 4] & 0x7f) << 21) |
          ((bytes[cursor + 5] & 0x7f) << 14) |
          ((bytes[cursor + 6] & 0x7f) << 7) |
          (bytes[cursor + 7] & 0x7f)
        : bytes.readUInt32BE(cursor + 4);
      const contentStart = cursor + 10;
      const contentEnd = contentStart + frameSize;
      if (frameSize <= 0 || contentEnd > end) break;
      const content = bytes.subarray(contentStart, contentEnd);

      const fieldMap = { TIT2: 'title', TPE1: 'artist', TALB: 'album', TLEN: 'durationMs' };
      if (fieldMap[frameId]) metadata[fieldMap[frameId]] = decodeId3Text(content);
      if (frameId === 'TCON') metadata.genre = decodeId3Text(content);
      if (frameId === 'APIC' && content.length > 5) {
        const encoding = content[0];
        const mimeEnd = content.indexOf(0, 1);
        if (mimeEnd > 1 && mimeEnd + 2 < content.length) {
          const mimeType = content.toString('latin1', 1, mimeEnd);
          const imageStart = encoding === 0 || encoding === 3
            ? content.indexOf(0, mimeEnd + 2) + 1
            : content.indexOf(Buffer.from([0, 0]), mimeEnd + 2) + 2;
          if (imageStart > 1 && imageStart < content.length) {
            const extension = mimeType === 'image/png' ? '.png' : '.jpg';
            pictures.push({ mimeType, extension, bytes: content.subarray(imageStart) });
          }
        }
      }
      cursor = contentEnd;
    }
  }

  if (bytes.length >= 128 && bytes.toString('ascii', bytes.length - 128, bytes.length - 125) === 'TAG') {
    const start = bytes.length - 128;
    const readV1 = (offset, length) => bytes
      .subarray(start + offset, start + offset + length)
      .toString('latin1').replace(/\0+$/g, '').trim();
    metadata.title ||= readV1(3, 30);
    metadata.artist ||= readV1(33, 30);
    metadata.album ||= readV1(63, 30);
  }

  if (metadata.durationMs && /^\d+$/.test(metadata.durationMs)) {
    metadata.durationSeconds = Math.round(Number(metadata.durationMs) / 1000);
  }
  return { metadata, pictures };
}

function csvEscape(value) {
  const text = String(value ?? '');
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function safeRelativeFile(root, filename) {
  const fullPath = path.resolve(root, filename);
  const relative = path.relative(path.resolve(root), fullPath);
  if (!relative || relative.startsWith('..') || path.isAbsolute(relative)) {
    throw new Error(`Cover path must stay inside the music folder: ${filename}`);
  }
  return fullPath;
}

async function listTracks(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith('.mp3'))
    .sort((left, right) => left.name.localeCompare(right.name, 'vi'));
}

async function writeTemplate(directory, csvPath) {
  const tracks = await listTracks(directory);
  const header = ['filename', 'title', 'artist', 'album', 'duration_seconds', 'genres', 'cover_filename'];
  const lines = [header.join(',')];
  for (const track of tracks) {
    const { metadata } = readId3(await readFile(path.join(directory, track.name)));
    lines.push([
      track.name,
      metadata.title ?? '',
      metadata.artist ?? '',
      metadata.album ?? '',
      metadata.durationSeconds ?? '',
      metadata.genre ?? '',
      '',
    ].map(csvEscape).join(','));
  }
  try {
    await writeFile(csvPath, `\uFEFF${lines.join('\r\n')}\r\n`, { encoding: 'utf8', flag: 'wx' });
  } catch (error) {
    if (error.code === 'EEXIST') {
      throw new Error(`CSV already exists and was not overwritten: ${csvPath}`);
    }
    throw error;
  }
  console.log(`Created ${csvPath} with ${tracks.length} MP3 rows.`);
}

async function request(url, options, operation = 'Supabase request') {
  const retryableStatuses = new Set([429, 500, 502, 503, 504]);
  const maxAttempts = 8;
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    let response;
    try {
      response = await fetch(url, options);
    } catch (error) {
      const cause = error.cause;
      const detail = [cause?.code, cause?.message ?? error.message]
        .filter(Boolean)
        .join(': ');
      if (attempt < maxAttempts - 1) {
        const delay = Math.min(1000 * (2 ** attempt), 15000);
        await new Promise((resolve) => setTimeout(resolve, delay));
        continue;
      }
      throw new Error(
        `${operation} could not reach Supabase after ${maxAttempts} attempts (${detail}). Check SUPABASE_URL and the network connection.`,
      );
    }

    if (response.ok) return response;
    const message = await response.text();
    if (retryableStatuses.has(response.status) && attempt < maxAttempts - 1) {
      const delay = Math.min(1000 * (2 ** attempt), 15000);
      await new Promise((resolve) => setTimeout(resolve, delay));
      continue;
    }
    const permissionHint = /row-level security|accessdenied/i.test(message)
      ? ' Check that SUPABASE_SERVICE_ROLE_KEY is the Secret key (sb_secret_...) or legacy service_role key for this project, not the Publishable/anon key. Do not add public write policies to work around this error.'
      : '';
    throw new Error(`${operation} failed (${response.status} ${response.statusText}): ${message}${permissionHint}`);
  }
}

async function uploadCover(apiUrl, headers, coverBytes, mimeType, extension) {
  const hash = createHash('sha256').update(coverBytes).digest('hex');
  const objectPath = `${hash}${extension}`;
  await request(`${apiUrl}/storage/v1/object/covers/${objectPath}`, {
    method: 'POST',
    headers: { ...headers, 'Content-Type': mimeType, 'x-upsert': 'true' },
    body: coverBytes,
  }, `Uploading cover ${objectPath}`);
  return objectPath;
}

async function findExistingSong(apiUrl, headers, filename) {
  const url = new URL(`${apiUrl}/rest/v1/songs`);
  url.searchParams.set('select', 'id,audio_path,title,artist,album,duration_seconds,cover_path,tags');
  url.searchParams.set('source_filename', `eq.${filename}`);
  const response = await request(url, { headers }, `Looking up ${filename}`);
  return (await response.json())[0] ?? null;
}

async function findLegacySong(apiUrl, headers, audioHash) {
  const url = new URL(`${apiUrl}/rest/v1/songs`);
  url.searchParams.set('select', 'id,audio_path,title,artist,album,duration_seconds,cover_path,tags');
  url.searchParams.set('audio_path', `eq.${audioHash}.mp3`);
  const response = await request(url, { headers }, `Looking up legacy audio ${audioHash}.mp3`);
  return (await response.json())[0] ?? null;
}

async function loadGenreMap(apiUrl, headers) {
  const url = new URL(`${apiUrl}/rest/v1/genres`);
  url.searchParams.set('select', 'code,name');
  const response = await request(url, { headers }, 'Loading genres');
  return new Map(
    (await response.json()).map((genre) => [genre.name.toLowerCase(), genre.code]),
  );
}

async function syncSongGenres(apiUrl, headers, songId, names, genreMap) {
  const codes = [];
  for (const rawName of names) {
    const name = rawName.trim();
    if (!name) continue;
    const key = name.toLowerCase();
    let code = genreMap.get(key);
    if (!code) {
      code = `g_${createHash('md5').update(key, 'utf8').digest('hex')}`;
      await request(`${apiUrl}/rest/v1/genres?on_conflict=code`, {
        method: 'POST',
        headers: {
          ...headers,
          'Content-Type': 'application/json',
          Prefer: 'resolution=merge-duplicates,return=minimal',
        },
        body: JSON.stringify([{ code, name }]),
      }, `Adding genre ${name}`);
      genreMap.set(key, code);
    }
    if (!codes.includes(code)) codes.push(code);
  }

  const deleteUrl = new URL(`${apiUrl}/rest/v1/song_genres`);
  deleteUrl.searchParams.set('song_id', `eq.${songId}`);
  await request(deleteUrl, {
    method: 'DELETE',
    headers: { ...headers, Prefer: 'return=minimal' },
  }, `Clearing genres for song ${songId}`);

  if (codes.length) {
    await request(`${apiUrl}/rest/v1/song_genres?on_conflict=song_id,genre_code`, {
      method: 'POST',
      headers: {
        ...headers,
        'Content-Type': 'application/json',
        Prefer: 'resolution=ignore-duplicates,return=minimal',
      },
      body: JSON.stringify(codes.map((genre_code) => ({ song_id: songId, genre_code }))),
    }, `Linking genres for song ${songId}`);
  }
}

async function importTracks(directory, csvPath) {
  const projectUrl = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!projectUrl || !serviceRoleKey) {
    throw new Error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before importing.');
  }

  const tracks = await listTracks(directory);
  if (tracks.length === 0) {
    console.log('No MP3 files found.');
    return;
  }
  const metadataRows = parseCsv(await readFile(csvPath, 'utf8'));
  const trackNames = new Set(tracks.map((track) => track.name));
  const metadataByFilename = new Map();
  for (const row of metadataRows) {
    if (metadataByFilename.has(row.filename)) {
      throw new Error(`CSV has more than one row for ${row.filename}.`);
    }
    if (!trackNames.has(row.filename)) {
      throw new Error(`CSV references an MP3 not found in the folder: ${row.filename}`);
    }
    metadataByFilename.set(row.filename, row);
  }

  const apiUrl = projectUrl.replace(/\/$/, '');
  const headers = {
    apikey: serviceRoleKey,
    ...(serviceRoleKey.startsWith('sb_secret_')
      ? {}
      : { Authorization: `Bearer ${serviceRoleKey}` }),
  };
  const genreMap = await loadGenreMap(apiUrl, headers);

  for (const [index, track] of tracks.entries()) {
    const bytes = await readFile(path.join(directory, track.name));
    const { metadata: id3, pictures } = readId3(bytes);
    const csv = metadataByFilename.get(track.name) ?? {};
    const audioHash = createHash('sha256').update(bytes).digest('hex');
    const nameHash = createHash('sha256').update(track.name, 'utf8').digest('hex');
    const audioPath = `${nameHash}/${audioHash}.mp3`;
    let existingSong = await findExistingSong(apiUrl, headers, track.name);
    if (!existingSong) {
      const legacySong = await findLegacySong(apiUrl, headers, audioHash);
      if (legacySong) {
        await request(`${apiUrl}/rest/v1/songs?id=eq.${legacySong.id}`, {
          method: 'PATCH',
          headers: { ...headers, 'Content-Type': 'application/json' },
          body: JSON.stringify({ source_filename: track.name }),
        }, `Migrating catalog entry for ${track.name}`);
        existingSong = legacySong;
      }
    }
    if (existingSong?.audio_path !== audioPath) {
      await request(`${apiUrl}/storage/v1/object/tracks/${audioPath}`, {
        method: 'POST',
        headers: { ...headers, 'Content-Type': 'audio/mpeg', 'x-upsert': 'true' },
        body: bytes,
      }, `Uploading audio ${track.name}`);
    }

    const payload = {
      source_filename: track.name,
      audio_path: audioPath,
      is_active: true,
      title: csv.title || id3.title || existingSong?.title || path.parse(track.name).name,
      artist: csv.artist || id3.artist || existingSong?.artist || 'Chưa rõ nghệ sĩ',
      album: csv.album || id3.album || existingSong?.album || '',
    };

    const csvDuration = csv.duration_seconds?.trim();
    const duration = csvDuration
      ? csvDuration
      : id3.durationSeconds ?? existingSong?.duration_seconds ?? 0;
    const seconds = Number(duration);
    if (!Number.isInteger(seconds) || seconds < 0) {
      throw new Error(`Invalid duration_seconds for ${track.name}: ${duration}`);
    }
    payload.duration_seconds = seconds;

    const genreInput = csv.genres || csv.tags;
    const tags = genreInput
      ? genreInput.split(';').map((tag) => tag.trim()).filter(Boolean)
      : id3.genre
        ? id3.genre.split(/[;,/]/).map((tag) => tag.trim()).filter(Boolean)
        : existingSong?.tags ?? [];
    payload.tags = [...new Map(tags.map((tag) => [tag.toLowerCase(), tag])).values()];

    let coverPath = existingSong?.cover_path ?? null;
    if (csv.cover_filename) {
      const coverBytes = await readFile(safeRelativeFile(directory, csv.cover_filename));
      const extension = path.extname(csv.cover_filename).toLowerCase();
      const mimeType = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp' }[extension];
      if (!mimeType) throw new Error(`Unsupported cover image type: ${csv.cover_filename}`);
      coverPath = await uploadCover(apiUrl, headers, coverBytes, mimeType, extension);
    } else if (pictures.length) {
      const picture = pictures[0];
      const mimeType = picture.mimeType === 'image/jpg' ? 'image/jpeg' : picture.mimeType;
      coverPath = await uploadCover(apiUrl, headers, picture.bytes, mimeType, picture.extension);
    }
    payload.cover_path = coverPath;

    await request(`${apiUrl}/rest/v1/songs?on_conflict=source_filename`, {
      method: 'POST',
      headers: {
        ...headers,
        'Content-Type': 'application/json',
        Prefer: 'resolution=merge-duplicates,return=minimal',
      },
      body: JSON.stringify([payload]),
    }, `Updating catalog entry for ${track.name}`);
    const importedSong = await findExistingSong(apiUrl, headers, track.name);
    if (!importedSong) throw new Error(`Could not find catalog row after importing ${track.name}.`);
    await syncSongGenres(apiUrl, headers, importedSong.id, payload.tags, genreMap);
    console.log(`[${index + 1}/${tracks.length}] Imported ${track.name}`);
  }
}

try {
  if (args[0] === '--help' || args.length === 0) {
    printUsage();
    process.exit(args.length === 0 ? 1 : 0);
  }

  if (args[0] === '--template') {
    if (args.length !== 3) throw new Error('Template mode requires a music folder and output CSV path.');
    await writeTemplate(args[1], args[2]);
  } else {
    if (args.length !== 2) throw new Error('Import mode requires a music folder and metadata CSV path.');
    await importTracks(args[0], args[1]);
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
