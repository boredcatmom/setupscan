# setupscan

> **FOR EDUCATIONAL PURPOSES ONLY. Do not run on production or sensitive environments.**

A pair of tools for inspecting and capturing environment variables over HTTP.

- `setupscan.sh` — scans env vars and optionally POSTs them as JSON
- `server.py` — receives the POST, stores entries to `data.txt`, and serves the file back

---

## Requirements

- Bash
- Python 3 (stdlib only — no installs needed)

---

## setupscan.sh

### Usage

```bash
./setupscan.sh [OPTIONS] [PATTERN]
```

### Options

| Flag | Description |
|------|-------------|
| `-a, --all` | Show all vars (default: sorted) |
| `-s, --secret` | Mask values of vars whose name contains SECRET, TOKEN, KEY, PASS, PASSWORD, CREDENTIAL, PRIVATE, or AUTH |
| `-e, --export` | Output as `export KEY=VALUE` lines |
| `-j, --json URL` | POST vars as JSON to the given URL |
| `-c, --count` | Print total count only |
| `-h, --help` | Show help |

### Examples

```bash
# List all env vars
./setupscan.sh

# Show vars matching a pattern
./setupscan.sh PATH

# Show AWS_* vars with secrets masked
./setupscan.sh -s AWS

# Dump as a sourceable shell file
./setupscan.sh -e > env.export

# POST all vars as JSON
./setupscan.sh -j http://localhost:8080

# POST only AWS_* vars, masking secrets
./setupscan.sh -j http://localhost:8080 -s AWS
```

---

## server.py

Minimal HTTP server that receives the JSON POST from `setupscan.sh`, appends each entry to `data.txt`, and serves the file back.

### Start the server

```bash
python3 server.py
# Serving on 0.0.0.0:8080
```

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/` | Receives JSON body, appends it to `data.txt` |
| `GET` | `/data.txt` | Returns the full contents of `data.txt` |

### Changing the port

Edit the `PORT` variable near the top of `server.py`:

```python
PORT = 8080
```

---

## End-to-end workflow

```bash
# Terminal 1 — start the server
python3 server.py

# Terminal 2 — send env vars
./setupscan.sh -j http://localhost:8080

# Read back the stored data
curl http://localhost:8080/data.txt
# or open http://localhost:8080/data.txt in a browser
```

### data.txt format

Each entry is separated by a header block:

```
============================================================
timestamp: 2026-04-08T14:32:01.123456+00:00
ip: 127.0.0.1
============================================================
{"HOME":"/home/boredcat","PATH":"/usr/bin:...","USER":"boredcat"}
```

Entries are appended on every POST, so the file accumulates a history of all submissions.
