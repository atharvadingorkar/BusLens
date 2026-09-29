import asyncio
import json
from datetime import datetime

import websockets


# Bus 101 demo route coordinates
route = [
    (19.2395, 73.1315),
    (19.2400, 73.1320),
    (19.2405, 73.1325),
    (19.2410, 73.1330),
    (19.2415, 73.1335),
    (19.2420, 73.1340),
]


async def simulate_bus():

    uri = "ws://127.0.0.1:8000/ws/live-location"

    async with websockets.connect(uri) as websocket:

        print("Connected to BusLens WebSocket")
        print("Starting Bus 101 GPS simulation...\n")

        for latitude, longitude in route:

            location = {
                "bus_id": 1,
                "latitude": latitude,
                "longitude": longitude,
                "timestamp": datetime.now().isoformat()
            }

            await websocket.send(json.dumps(location))

            print(
                f"Bus 101 → "
                f"Latitude: {latitude}, "
                f"Longitude: {longitude}"
            )

            await asyncio.sleep(3)


asyncio.run(simulate_bus())