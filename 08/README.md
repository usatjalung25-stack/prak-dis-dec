Last login: Fri Nov 20 00:23:01 on ttys000
danel@1111QD-rs ~ % sqlite3 --version
3.54.1 2026-10-16 14:45:20 555e07ef33f69a0957d24d8e555b702464a131d6f1607f4c3c1e4551e8e6ca76 (64-bit)
danel@1111QD-rs ~ % mkdir -p ~/modul8 && cd ~/modul8
danel@1111QD-rs modul8 % uv python install 3.14
Python 3.14 is already installed
danel@1111QD-rs modul8 % uv python pin 3.14
Pinned `.python-version` to `3.14`
danel@1111QD-rs modul8 % uv venv
Using CPython 3.14.10
Creating virtual environment at: .venv
? A virtual environment already exists at `.venv`. Do you want to replace it? [y✔ A virtual environment already exists at `.venv`. Do you want to replace it? · yes
Activate with: source .venv/bin/activate
danel@1111QD-rs modul8 % source .venv/bin/activate
(modul8) danel@1111QD-rs modul8 % uv pip install "fastapi[standard]" sqlmodel
Resolved 61 packages in 71ms
Installed 61 packages in 193ms
 + agent-detector==2.0.0
 + annotated-doc==0.0.7
 + annotated-types==0.8.0
 + anyio==4.16.0
 + certifi==2026.10.23
 + charset-normalizer==3.5.2
 + click==8.5.1
 + detect-installer==0.2.1
 + dnspython==2.9.2
 + email-validator==2.4.0
 + fastapi==0.165.0
 + fastapi-cli==0.0.34
 + fastapi-cloud-cli==0.28.0
 + fastar==0.12.0
 + googleapis-common-protos==1.76.0
 + h11==0.16.0
 + httpcore==1.0.9
 + httpcore2==2.16.2
 + httptools==0.9.0
 + httpx==0.28.1
 + httpx2==2.16.2
 + idna==3.20
 + jinja2==3.1.6
 + markdown-it-py==4.3.0
 + markupsafe==3.0.4
 + mdurl==0.1.2
 + opentelemetry-api==1.45.2
 + opentelemetry-exporter-http-transport==0.66b2
 + opentelemetry-exporter-otlp-common==0.66b2
 + opentelemetry-exporter-otlp-proto-common==1.45.2
 + opentelemetry-exporter-otlp-proto-http==1.45.2
 + opentelemetry-proto==1.45.2
 + opentelemetry-sdk==1.45.2
 + opentelemetry-semantic-conventions==0.66b2
 + protobuf==7.36.2
 + pydantic==2.14.4
 + pydantic-core==2.50.5
 + pydantic-extra-types==2.11.1
 + pydantic-settings==2.16.3
 + pygments==2.21.0
 + python-dotenv==1.2.4
 + python-multipart==0.0.34
 + pyyaml==6.0.3
 + requests==2.34.2
 + rich==15.0.0
 + rich-toolkit==0.20.6
 + rignore==0.8.1
 + sentry-sdk==2.75.0
 + shellingham==1.5.4
 + sqlalchemy==2.1.9
 + sqlmodel==0.0.50
 + starlette==1.10.0
 + truststore==0.10.5
 + typer==0.29.2
 + typing-extensions==4.16.0
 + typing-inspection==0.4.5
 + urllib3==2.8.0
 + uvicorn==0.54.0
 + uvloop==0.23.0
 + watchfiles==1.3.0
 + websockets==17.4
(modul8) danel@1111QD-rs modul8 % mkdir -p ~/modul8/contoh && cd ~/modul8/contoh 
(modul8) danel@1111QD-rs contoh % sqlite3 departemen-sdm.db <<'EOF'
CREATE TABLE sdm (id INTEGER PRIMARY KEY, npp CHAR(6), nama VARCHAR(50));
INSERT INTO sdm (npp, nama) VALUES ('112233', 'Karyawan 1');
INSERT INTO sdm (npp, nama) VALUES ('223344', 'Karyawan 2');
INSERT INTO sdm (npp, nama) VALUES ('334455', 'Karyawan 3');
SELECT * FROM sdm;
EOF
Parse error near line 1: table sdm already exists
  CREATE TABLE sdm (id INTEGER PRIMARY KEY, npp CHAR(6), nama VARCHAR(50));
               ^--- error here
╭────┬──────────┬────────────╮
│ id │   npp    │    nama    │
╞════╪══════════╪════════════╡
│  1 │ '112233' │ Karyawan 1 │
│  2 │ '223344' │ Karyawan 2 │
│  3 │ '334455' │ Karyawan 3 │
│  4 │ '112233' │ Karyawan 1 │
│  5 │ '223344' │ Karyawan 2 │
│  6 │ '334455' │ Karyawan 3 │
╰────┴──────────┴────────────╯
(modul8) danel@1111QD-rs contoh % rm departemen-sdm.db && sqlite3 departemen-sdm.db <<'EOF'
CREATE TABLE sdm (id INTEGER PRIMARY KEY, npp CHAR(6), nama VARCHAR(50));
INSERT INTO sdm (npp, nama) VALUES ('112233', 'Karyawan 1');
INSERT INTO sdm (npp, nama) VALUES ('223344', 'Karyawan 2');
INSERT INTO sdm (npp, nama) VALUES ('334455', 'Karyawan 3');
SELECT * FROM sdm;
EOF

╭────┬──────────┬────────────╮
│ id │   npp    │    nama    │
╞════╪══════════╪════════════╡
│  1 │ '112233' │ Karyawan 1 │
│  2 │ '223344' │ Karyawan 2 │
│  3 │ '334455' │ Karyawan 3 │
╰────┴──────────┴────────────╯
(modul8) danel@1111QD-rs contoh % >....                                         
    id: int | None = Field(default=None, primary_key=True)
    npp: str
    nama: str


engine = create_engine("sqlite:///departemen-sdm.db")


def get_session():
    with Session(engine) as session:
        yield session


app = FastAPI()


@app.get("/sdm/", response_model=List[Sdm])
def read_sdm(session: Session = Depends(get_session)):
    # SQLModel select statement
    statement = select(Sdm)
    results = session.exec(statement).all()
    return results
EOF
(modul8) danel@1111QD-rs contoh % uvicorn service:app --reload
INFO:     Will watch for changes in these directories: ['/Users/danel/modul8/contoh']
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [41208] using WatchFiles
INFO:     Started server process [41210]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     127.0.0.1:51755 - "GET /sdm/ HTTP/1.1" 200 OK
INFO:     127.0.0.1:51764 - "GET /sdm/ HTTP/1.1" 200 OK


