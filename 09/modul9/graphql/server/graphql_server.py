import typing

import strawberry
from sqlmodel import Field, Session, SQLModel, create_engine, select
from strawberry.asgi import GraphQL


class Buku(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    kode: str
    judul: str
    tahun_terbit: int
    harga_sewa: float
    tersedia: bool


engine = create_engine("sqlite:///perpustakaan.db")


@strawberry.type
class BukuType:
    id: int
    kode: str
    judul: str
    tahun_terbit: int
    harga_sewa: float
    tersedia: bool


def get_buku() -> typing.List[BukuType]:
    with Session(engine) as session:
        rows = session.exec(select(Buku)).all()
        return [
            BukuType(
                id=r.id,
                kode=r.kode,
                judul=r.judul,
                tahun_terbit=r.tahun_terbit,
                harga_sewa=r.harga_sewa,
                tersedia=r.tersedia,
            )
            for r in rows
        ]


@strawberry.type
class Query:
    buku: typing.List[BukuType] = strawberry.field(resolver=get_buku)


schema = strawberry.Schema(query=Query)
app = GraphQL(schema)
