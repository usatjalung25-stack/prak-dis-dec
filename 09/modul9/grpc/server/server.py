import grpc
from concurrent import futures
from sqlmodel import Field, Session, SQLModel, create_engine, select

import service_pb2
import service_pb2_grpc


class Buku(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    kode: str
    judul: str
    tahun_terbit: int
    harga_sewa: float
    tersedia: bool


engine = create_engine("sqlite:///perpustakaan.db")


class BukuServiceServicer(service_pb2_grpc.BukuServiceServicer):
    def GetBuku(self, request, context):
        with Session(engine) as session:
            statement = select(Buku).where(Buku.id == request.id)
            results = session.exec(statement)
            buku = results.first()
            if buku is None:
                context.set_code(grpc.StatusCode.NOT_FOUND)
                context.set_details("Buku not found")
                return service_pb2.BukuResponse()

            return service_pb2.BukuResponse(
                id=buku.id,
                kode=buku.kode,
                judul=buku.judul,
                tahun_terbit=buku.tahun_terbit,
                harga_sewa=buku.harga_sewa,
                tersedia=buku.tersedia,
            )


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    service_pb2_grpc.add_BukuServiceServicer_to_server(BukuServiceServicer(), server)
    server.add_insecure_port('[::]:50051')
    print("Server started. Listening on port 50051...")
    server.start()
    server.wait_for_termination()


if __name__ == '__main__':
    serve()
