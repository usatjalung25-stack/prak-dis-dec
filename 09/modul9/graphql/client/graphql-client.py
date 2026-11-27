import asyncio

from gql import Client, gql
from gql.transport.aiohttp import AIOHTTPTransport


async def main():
    transport = AIOHTTPTransport(url="http://localhost:8000/graphql")
    client = Client(transport=transport)

    query = gql(
        """
        query getBuku {
          buku {
            id
            kode
            judul
            tahunTerbit
            hargaSewa
            tersedia
          }
        }
        """
    )

    async with client as session:
        result = await session.execute(query)
        for row in result["buku"]:
            print(row)


asyncio.run(main())
