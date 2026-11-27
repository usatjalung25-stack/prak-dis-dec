import typing
import strawberry
from sqlmodel import Field, Session, SQLModel, create_engine, select


@strawberry.type
class Sdm(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    npp: str
    nama: str


engine = create_engine("sqlite:///departemen-sdm.db")


def get_sdms():
    with Session(engine) as session:
        statement = select(Sdm)
        results = session.exec(statement).all()
    return results


@strawberry.type
class Query:
    sdms: typing.List[Sdm] = strawberry.field(resolver=get_sdms)


schema = strawberry.Schema(query=Query)
