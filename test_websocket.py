import asyncio
import json
import websockets


async def test_websocket():

    uri = "wss://buslens-api.onrender.com/ws/live-location"

    async with websockets.connect(uri) as websocket:

        message = await websocket.recv()

        print("Server:", message)

        location = {
            "bus_id": 1,
            "latitude": 19.2400,
            "longitude": 73.1320,
            "timestamp": "2026-09-10T18:00:00"
        }

        await websocket.send(json.dumps(location))

        response = await websocket.recv()

        print("Location Response:", response)


asyncio.run(test_websocket())