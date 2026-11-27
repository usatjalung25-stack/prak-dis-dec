import grpc
import service_pb2
import service_pb2_grpc


def run_client():
    with grpc.insecure_channel('localhost:50051') as channel:
        stub = service_pb2_grpc.BukuServiceStub(channel)

        request = service_pb2.BukuRequest(id=1)
        try:
            r = stub.GetBuku(request)
            print(f"id={r.id} kode={r.kode} judul={r.judul} "
                  f"tahun_terbit={r.tahun_terbit} harga_sewa={r.harga_sewa} "
                  f"tersedia={r.tersedia}")
        except grpc.RpcError as e:
            print(f"Error: {e.code()} - {e.details()}")

        request_not_found = service_pb2.BukuRequest(id=10000)
        try:
            r = stub.GetBuku(request_not_found)
            print(f"Judul: {r.judul}")
        except grpc.RpcError as e:
            print(f"Error: {e.code()} - {e.details()}")


if __name__ == '__main__':
    run_client()
