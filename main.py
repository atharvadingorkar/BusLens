from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from database import get_connection
import bcrypt
import pandas as pd
import joblib
from datetime import datetime
from config import razorpay_client, RAZORPAY_KEY_ID
from razorpay.errors import SignatureVerificationError
from fastapi.middleware.cors import CORSMiddleware
app = FastAPI(title="BusLens API")
app.add_middleware(
    CORSMiddleware,
   allow_origin_regex=r"https?://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
eta_model = joblib.load("eta_model.pkl")

class LoginRequest(BaseModel):
    email: str
    password: str
    role: str

class AdminCreateOperatorRequest(BaseModel):
    admin_email: str
    admin_password: str

    full_name: str
    email: str
    phone: str
    password: str

class UpdateOperatorStatusRequest(BaseModel):
    status: str

class RegisterRequest(BaseModel):
    full_name: str
    email: str
    phone: str
    password: str

class LocationUpdate(BaseModel):
    bus_id: int
    latitude: float
    longitude: float
    timestamp: str

class ETAPredictionRequest(BaseModel):
    bus_id: int
    route_id: int
    source_stop_id: int
    destination_stop_id: int
    departure_hour: int
    weather: str
    traffic_level: str

class CreateOrderRequest(BaseModel):
    user_id: int
    bus_id: int
    source_stop_id: int
    destination_stop_id: int
    fare: float

class VerifyPaymentRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str
    
class RecommendationRequest(BaseModel):
    source_stop_id: int
    destination_stop_id: int

class TicketBookingRequest(BaseModel):
    user_id: int
    bus_id: int
    source_stop_id: int
    destination_stop_id: int
    fare: float

class FareRequest(BaseModel):
    bus_id: int
    source_stop_id: int
    destination_stop_id: int

class StartTripRequest(BaseModel):
    bus_id: int
    route_id: int
    weather: str = "clear"
    traffic_level: str = "moderate"

class EndTripRequest(BaseModel):
    bus_id: int

class AddBusRequest(BaseModel):
    bus_number: str
    bus_name: str
    capacity: int

class AddRouteRequest(BaseModel):
    route_name: str
    source: str
    destination: str
    distance_km: float

class UpdateRouteStatusRequest(BaseModel):
    status: str

class UpdateBusStatusRequest(BaseModel):
    status: str

class AssignBusRequest(BaseModel):
    operator_id: int
    bus_id: int

class AddRouteStopRequest(BaseModel):
    route_id: int
    stop_id: int
    stop_order: int


class UpdateBusLocationRequest(BaseModel):
    bus_id: int
    latitude: float
    longitude: float
    speed: float = 0.0

@app.get("/")
def home():
    return {
        "message": "BusLens backend is running!"
    }


@app.get("/buses")
def get_buses():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT bus_id, bus_number, bus_name, capacity, status
        FROM buses
        ORDER BY bus_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    buses = []

    for row in rows:
        buses.append({
            "bus_id": row[0],
            "bus_number": row[1],
            "bus_name": row[2],
            "capacity": row[3],
            "status": row[4]
        })

    return {
        "buses": buses
    }

@app.post("/login")
def login(request: LoginRequest):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT user_id, full_name, email, password_hash, role
        FROM users
        WHERE email = %s
        AND role = %s;
    """, (
        request.email,
        request.role.lower()
    ))

    row = cursor.fetchone()

    cursor.close()
    conn.close()

    if row is None:
        return {
            "success": False,
            "message": "Invalid email or role"
        }

    password_hash = row[3]

    password_matches = bcrypt.checkpw(
        request.password.encode("utf-8"),
        password_hash.encode("utf-8")
    )

    if not password_matches:
        return {
            "success": False,
            "message": "Invalid password"
        }

    return {
        "success": True,
        "message": "Login successful",
        "user_id": row[0],
        "full_name": row[1],    
        "email": row[2],
        "role": row[4]
    }

@app.post("/admin/create-operator")
def create_operator(request: AdminCreateOperatorRequest):

    conn = get_connection()
    cursor = conn.cursor()

    try:
        # 1. Verify Admin credentials
        cursor.execute("""
            SELECT password_hash
            FROM users
            WHERE email = %s
            AND role = 'admin';
        """, (request.admin_email,))

        admin_row = cursor.fetchone()

        if admin_row is None:
            return {
                "success": False,
                "message": "Invalid Admin email"
            }

        admin_password_hash = admin_row[0]

        admin_password_matches = bcrypt.checkpw(
            request.admin_password.encode("utf-8"),
            admin_password_hash.encode("utf-8")
        )

        if not admin_password_matches:
            return {
                "success": False,
                "message": "Invalid Admin password"
            }

        # 2. Check whether the operator email already exists
        cursor.execute("""
            SELECT user_id
            FROM users
            WHERE email = %s;
        """, (request.email,))

        existing_user = cursor.fetchone()

        if existing_user is not None:
            return {
                "success": False,
                "message": "Email already exists"
            }

        # 3. Hash the operator password
        password_hash = bcrypt.hashpw(
            request.password.encode("utf-8"),
            bcrypt.gensalt()
        ).decode("utf-8")

        # 4. Create the operator account
        cursor.execute("""
            INSERT INTO users (
                full_name,
                email,
                phone,
                password_hash,
                role,
                status
            )
            VALUES (%s, %s, %s, %s, 'operator', 'active')
            RETURNING user_id;
        """, (
            request.full_name,
            request.email,
            request.phone,
            password_hash
        ))

        new_operator_id = cursor.fetchone()[0]

        conn.commit()

        return {
            "success": True,
            "message": "Operator account created successfully",
            "user_id": new_operator_id,
            "email": request.email,
            "role": "operator"
        }

    except Exception as e:
        conn.rollback()

        return {
            "success": False,
            "message": "Unable to create operator account"
        }

    finally:
        cursor.close()
        conn.close()

@app.post("/admin/assign-bus")
def assign_bus_to_operator(request: AssignBusRequest):

    conn = get_connection()
    cursor = conn.cursor()

    try:

        # Check whether the operator exists
        cursor.execute("""
            SELECT user_id
            FROM users
            WHERE user_id = %s
            AND role = 'operator';
        """, (request.operator_id,))

        operator = cursor.fetchone()

        if operator is None:
            return {
                "success": False,
                "message": "Operator not found"
            }

        # Check whether the bus exists
        cursor.execute("""
            SELECT bus_id, status
            FROM buses
            WHERE bus_id = %s;
        """, (request.bus_id,))

        bus = cursor.fetchone()

        if bus is None:
            return {
                "success": False,
                "message": "Bus not found"
            }

        # Only active buses can be assigned
        if bus[1].lower() != "active":
            return {
                "success": False,
                "message": "Only active buses can be assigned"
            }

        # Check whether the bus is already assigned
        cursor.execute("""
            SELECT assignment_id
            FROM bus_assignment
            WHERE bus_id = %s;
        """, (request.bus_id,))

        existing_assignment = cursor.fetchone()

        if existing_assignment is not None:
            return {
                "success": False,
                "message": "This bus is already assigned"
            }

        # Assign the bus to the operator
        cursor.execute("""
            INSERT INTO bus_assignment (
                operator_id,
                bus_id,
                assigned_date
            )
            VALUES (%s, %s, CURRENT_DATE)
            RETURNING assignment_id;
        """, (
            request.operator_id,
            request.bus_id
        ))

        assignment_id = cursor.fetchone()[0]

        conn.commit()

        return {
            "success": True,
            "message": "Bus assigned successfully",
            "assignment_id": assignment_id,
            "operator_id": request.operator_id,
            "bus_id": request.bus_id
        }

    except Exception as e:

        conn.rollback()

        return {
            "success": False,
            "message": str(e)
        }

    finally:

        cursor.close()
        conn.close()

@app.get("/routes")
def get_routes():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            route_id,
            route_name,
            source,
            destination,
            distance_km,
            status
        FROM routes
        ORDER BY route_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    routes = []

    for row in rows:
        routes.append({
            "route_id": row[0],
            "route_name": row[1],
            "source": row[2],
            "destination": row[3],
            "distance_km": float(row[4]),
            "status": row[5]
        })

    return {
        "routes": routes
    }

@app.put("/route/{route_id}/status")
def update_route_status(
    route_id: int,
    request: UpdateRouteStatusRequest
):
    if request.status not in ["active", "inactive"]:
        return {
            "success": False,
            "message": "Status must be active or inactive"
        }

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT route_id
        FROM routes
        WHERE route_id = %s;
    """, (route_id,))

    route = cursor.fetchone()

    if route is None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Route not found"
        }

    cursor.execute("""
        UPDATE routes
        SET status = %s
        WHERE route_id = %s
        RETURNING route_id, route_name, status;
    """, (request.status, route_id))

    updated_route = cursor.fetchone()

    conn.commit()

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Route status updated successfully",
        "route_id": updated_route[0],
        "route_name": updated_route[1],
        "status": updated_route[2]
    }

@app.get("/stops")
def get_stops():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT stop_id, stop_name, latitude, longitude
        FROM stops
        ORDER BY stop_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    stops = []

    for row in rows:
        stops.append({
            "stop_id": row[0],
            "stop_name": row[1],
            "latitude": float(row[2]),
            "longitude": float(row[3])
        })

    return {
        "stops": stops
    }

@app.get("/route-stops/{route_id}")
def get_route_stops(route_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            rs.route_id,
            rs.stop_id,
            s.stop_name,
            rs.stop_order
        FROM route_stops rs
        JOIN stops s
            ON rs.stop_id = s.stop_id
        WHERE rs.route_id = %s
        ORDER BY rs.stop_order;
    """, (route_id,))

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    route_stops = []

    for row in rows:
        route_stops.append({
            "route_id": row[0],
            "stop_id": row[1],
            "stop_name": row[2],
            "stop_order": row[3]
        })

    return {
        "route_id": route_id,
        "stops": route_stops
    }

@app.post("/admin/add-route-stop")
def add_route_stop(request: AddRouteStopRequest):
    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Check whether the route exists
        cursor.execute(
            """
            SELECT route_id
            FROM routes
            WHERE route_id = %s;
            """,
            (request.route_id,)
        )

        route = cursor.fetchone()

        if route is None:
            return {
                "success": False,
                "message": "Route not found"
            }

        # Check whether the stop exists
        cursor.execute(
            """
            SELECT stop_id
            FROM stops
            WHERE stop_id = %s;
            """,
            (request.stop_id,)
        )

        stop = cursor.fetchone()

        if stop is None:
            return {
                "success": False,
                "message": "Stop not found"
            }

        # Check whether this stop is already assigned
        cursor.execute(
            """
            SELECT route_id
            FROM route_stops
            WHERE route_id = %s
              AND stop_id = %s;
            """,
            (request.route_id, request.stop_id)
        )

        existing_stop = cursor.fetchone()

        if existing_stop is not None:
            return {
                "success": False,
                "message": "This stop is already assigned to the route"
            }

        # Add the stop to the route
        cursor.execute(
            """
            INSERT INTO route_stops (
                route_id,
                stop_id,
                stop_order
            )
            VALUES (%s, %s, %s);
            """,
            (
                request.route_id,
                request.stop_id,
                request.stop_order
            )
        )

        conn.commit()

        return {
            "success": True,
            "message": "Bus stop added to route successfully"
        }

    except Exception as e:
        conn.rollback()

        return {
            "success": False,
            "message": "Failed to add bus stop to route",
            "error": str(e)
        }

    finally:
        cursor.close()
        conn.close()

@app.get("/bus-locations")
def get_bus_locations():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            bl.location_id,
            bl.bus_id,
            b.bus_number,
            b.bus_name,
            bl.latitude,
            bl.longitude,
            bl.speed,
            bl.updated_at
        FROM bus_locations bl
        JOIN buses b ON bl.bus_id = b.bus_id
        ORDER BY bl.bus_id, bl.updated_at DESC;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    locations = []

    for row in rows:
        locations.append({
            "location_id": row[0],
            "bus_id": row[1],
            "bus_number": row[2],
            "bus_name": row[3],
            "latitude": float(row[4]),
            "longitude": float(row[5]),
            "speed": float(row[6]),
            "updated_at": row[7]
        })

    return {
        "bus_locations": locations
    }
@app.get("/trips")
def get_trips():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            th.trip_id,
            th.bus_id,
            b.bus_number,
            th.route_id,
            r.route_name,
            r.source,
            r.destination,
            r.distance_km,
            th.travel_date,
            th.departure_time,
            th.arrival_time,
            th.travel_duration,
            th.weather,
            th.traffic_level
        FROM trip_history th
        JOIN buses b ON th.bus_id = b.bus_id
        JOIN routes r ON th.route_id = r.route_id
        ORDER BY th.trip_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    trips = []

    for row in rows:
        trips.append({
            "trip_id": row[0],
            "bus_id": row[1],
            "bus_number": row[2],
            "route_id": row[3],
            "route_name": row[4],
            "source": row[5],
            "destination": row[6],
            "distance_km": float(row[7]),
            "travel_date": row[8],
            "departure_time": row[9],
            "arrival_time": row[10],
            "travel_duration": row[11],
            "weather": row[12],
            "traffic_level": row[13]
        })

    return {
        "trips": trips
    }
@app.get("/tickets")
def get_tickets():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            t.ticket_id,
            u.full_name,
            b.bus_number,
            s1.stop_name AS source,
            s2.stop_name AS destination,
            t.fare,
            t.ticket_status
        FROM tickets t
        JOIN users u ON t.user_id = u.user_id
        JOIN buses b ON t.bus_id = b.bus_id
        JOIN stops s1 ON t.source_stop_id = s1.stop_id
        JOIN stops s2 ON t.destination_stop_id = s2.stop_id
        ORDER BY t.ticket_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    tickets = []

    for row in rows:
        tickets.append({
            "ticket_id": row[0],
            "passenger": row[1],
            "bus_number": row[2],
            "source": row[3],
            "destination": row[4],
            "fare": float(row[5]),
            "ticket_status": row[6]
        })

    return {
        "tickets": tickets
    }
@app.get("/payments")
def get_payments():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            p.payment_id,
            p.ticket_id,
            p.amount,
            p.payment_method,
            p.payment_status,
            p.payment_time
        FROM payments p
        ORDER BY p.payment_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    payments = []

    for row in rows:
        payments.append({
            "payment_id": row[0],
            "ticket_id": row[1],
            "amount": float(row[2]),
            "payment_method": row[3],
            "payment_status": row[4],
            "payment_time": str(row[5])
        })

    return {
        "payments": payments
    }

@app.get("/recommendations")
def get_recommendations():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            r.recommendation_id,
            u.full_name,
            b.bus_number,
            s1.stop_name AS source,
            s2.stop_name AS destination,
            r.predicted_eta
        FROM recommendations r
        JOIN users u ON r.user_id = u.user_id
        JOIN buses b ON r.recommendation_bus_id = b.bus_id
        JOIN stops s1 ON r.source_stop_id = s1.stop_id
        JOIN stops s2 ON r.destination_stop_id = s2.stop_id
        ORDER BY r.recommendation_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    recommendations = []

    for row in rows:
        recommendations.append({
            "recommendation_id": row[0],
            "passenger": row[1],
            "bus_number": row[2],
            "source": row[3],
            "destination": row[4],
            "predicted_eta": row[5]
        })

    return {
        "recommendations": recommendations
    }

@app.get("/bus/{bus_id}/route")
def get_bus_route(bus_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            b.bus_id,
            b.bus_number,
            b.bus_name,
            r.route_id,
            r.route_name,
            r.source,
            r.destination,
            r.distance_km,
            s.stop_id,
            s.stop_name,
            s.latitude,
            s.longitude,
            rs.stop_order
        FROM buses b
        JOIN routes r
            ON b.bus_name = r.route_name
        JOIN route_stops rs
            ON r.route_id = rs.route_id
        JOIN stops s
            ON rs.stop_id = s.stop_id
        WHERE b.bus_id = %s
        ORDER BY rs.stop_order;
    """, (bus_id,))

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    if not rows:
        return {
            "success": False,
            "message": "Bus route not found"
        }

    stops = []

    for row in rows:
        stops.append({
            "stop_id": row[8],
            "stop_name": row[9],
            "latitude": float(row[10]),
            "longitude": float(row[11]),
            "stop_order": row[12]
        })

    return {
        "success": True,
        "bus_id": rows[0][0],
        "bus_number": rows[0][1],
        "bus_name": rows[0][2],
        "route_id": rows[0][3],
        "route_name": rows[0][4],
        "source": rows[0][5],
        "destination": rows[0][6],
        "distance_km": float(rows[0][7]),
        "stops": stops
    }

@app.post("/register")
def register(request: RegisterRequest):

    conn = get_connection()
    cursor = conn.cursor()

    # Check if email already exists
    cursor.execute("""
        SELECT user_id
        FROM users
        WHERE email = %s;
    """, (request.email,))

    existing_user = cursor.fetchone()

    if existing_user is not None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Email already registered"
        }

    # Hash the password
    password_hash = bcrypt.hashpw(
        request.password.encode("utf-8"),
        bcrypt.gensalt()
    ).decode("utf-8")

    # Create passenger account
    cursor.execute("""
        INSERT INTO users
        (full_name, email, phone, password_hash, role)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING user_id;
    """, (
        request.full_name,
        request.email,
        request.phone,
        password_hash,
        "passenger"
    ))

    user_id = cursor.fetchone()[0]

    conn.commit()

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Registration successful",
        "user_id": user_id,
        "role": "passenger"
    }

@app.get("/bus/{bus_id}/location")
def get_bus_location(bus_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            bus_id,
            latitude,
            longitude,
            updated_at
        FROM bus_locations
        WHERE bus_id = %s
        ORDER BY updated_at DESC
        LIMIT 1;
    """, (bus_id,))

    row = cursor.fetchone()

    cursor.close()
    conn.close()

    if row is None:
        return {
            "success": False,
            "message": "Bus location not found"
        }

    return {
        "success": True,
        "bus_id": row[0],
        "latitude": float(row[1]),
        "longitude": float(row[2]),
        "updated_at": row[3]
    }

# ==============================
# WEBSOCKET CONNECTION MANAGER
# ==============================

class ConnectionManager:

    def __init__(self):
        self.active_connections = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            await connection.send_json(message)


manager = ConnectionManager()


# ==============================
# WEBSOCKET LIVE TRACKING
# ==============================

@app.websocket("/ws/live-location")
async def live_location_websocket(websocket: WebSocket):

    await manager.connect(websocket)

    try:

        await websocket.send_json({
            "success": True,
            "message": "Connected to BusLens live tracking"
        })

        while True:

            data = await websocket.receive_json()

            location = LocationUpdate(**data)

            # Save GPS location to database
            conn = get_connection()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO bus_locations
                (bus_id, latitude, longitude, updated_at)
                VALUES (%s, %s, %s, %s)
            """, (
                location.bus_id,
                location.latitude,
                location.longitude,
                location.timestamp
            ))

            conn.commit()

            cursor.close()
            conn.close()

            # Prepare WebSocket response
            message = {
                "success": True,
                "bus_id": location.bus_id,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "timestamp": location.timestamp
            }

            # Send location to connected clients
            await manager.broadcast(message)

    except WebSocketDisconnect:

        manager.disconnect(websocket)

@app.post("/predict-eta")
def predict_eta(request: ETAPredictionRequest):

    conn = get_connection()
    cursor = conn.cursor()

    # ---------------------------------------------------------
    # 1. Get the selected bus and route
    # ---------------------------------------------------------
    cursor.execute("""
        SELECT
            b.bus_id,
            b.bus_number,
            r.route_id,
            r.route_name
        FROM buses b
        JOIN routes r
            ON b.bus_name = r.route_name
        WHERE b.bus_id = %s
          AND r.route_id = %s;
    """, (
        request.bus_id,
        request.route_id
    ))

    bus_route = cursor.fetchone()

    if bus_route is None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Selected bus and route not found"
        }

    # ---------------------------------------------------------
    # 2. Get source and destination stop order
    # ---------------------------------------------------------
    cursor.execute("""
        SELECT
            rs1.stop_order,
            rs2.stop_order
        FROM route_stops rs1
        JOIN route_stops rs2
            ON rs1.route_id = rs2.route_id
        WHERE rs1.route_id = %s
          AND rs1.stop_id = %s
          AND rs2.stop_id = %s;
    """, (
        request.route_id,
        request.source_stop_id,
        request.destination_stop_id
    ))

    stop_orders = cursor.fetchone()

    if stop_orders is None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Selected source and destination are not on this route"
        }

    source_order = stop_orders[0]
    destination_order = stop_orders[1]

    # ---------------------------------------------------------
    # 3. Make sure destination comes after source
    # ---------------------------------------------------------
    if source_order >= destination_order:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Destination must be after the source stop"
        }

    # ---------------------------------------------------------
    # 4. Get the latest GPS location of the selected bus
    # ---------------------------------------------------------
    cursor.execute("""
        SELECT
            latitude,
            longitude,
            updated_at
        FROM bus_locations
        WHERE bus_id = %s
        ORDER BY updated_at DESC
        LIMIT 1;
    """, (
        request.bus_id,
    ))

    location = cursor.fetchone()

    if location is None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Current bus location is not available"
        }

    bus_latitude = float(location[0])
    bus_longitude = float(location[1])

    # ---------------------------------------------------------
    # 5. Get all stops for this route
    # ---------------------------------------------------------
    cursor.execute("""
        SELECT
            s.stop_id,
            s.stop_name,
            s.latitude,
            s.longitude,
            rs.stop_order
        FROM route_stops rs
        JOIN stops s
            ON rs.stop_id = s.stop_id
        WHERE rs.route_id = %s
        ORDER BY rs.stop_order;
    """, (
        request.route_id,
    ))

    route_stops = cursor.fetchall()

    cursor.close()
    conn.close()

    if not route_stops:
        return {
            "success": False,
            "message": "Route stops not found"
        }

    # ---------------------------------------------------------
    # 6. Find the route stop nearest to the current bus location
    # ---------------------------------------------------------
    import math

    def calculate_distance(
        lat1,
        lon1,
        lat2,
        lon2
    ):
        lat_difference = lat2 - lat1
        lon_difference = lon2 - lon1

        return math.sqrt(
            (lat_difference * 111000) ** 2 +
            (lon_difference * 111000) ** 2
        )

    nearest_stop = None
    nearest_distance = None

    for stop in route_stops:

        distance = calculate_distance(
            bus_latitude,
            bus_longitude,
            float(stop[2]),
            float(stop[3])
        )

        if nearest_distance is None or distance < nearest_distance:
            nearest_distance = distance
            nearest_stop = stop

    current_stop_order = nearest_stop[4]
    current_stop_name = nearest_stop[1]

    # ---------------------------------------------------------
    # 7. Check whether the bus has already reached destination
    # ---------------------------------------------------------
    if current_stop_order >= destination_order:

        return {
            "success": False,
            "message": "Bus has already reached or passed the selected destination",
            "bus_id": request.bus_id,
            "route_id": request.route_id,
            "current_stop": current_stop_name
        }

    # ---------------------------------------------------------
    # 8. Prepare input for Random Forest
    # ---------------------------------------------------------
    input_data = pd.DataFrame([
        {
            "bus_id": request.bus_id,
            "route_id": request.route_id,
            "departure_hour": request.departure_hour,
            "weather": request.weather,
            "traffic_level": request.traffic_level
        }
    ])

    # ---------------------------------------------------------
    # 9. Predict total journey duration using Random Forest
    # ---------------------------------------------------------
    prediction = eta_model.predict(input_data)[0]

    predicted_total_duration = float(prediction)

    # ---------------------------------------------------------
    # 10. Calculate remaining journey fraction
    # ---------------------------------------------------------
    selected_journey_stops = (
        destination_order - source_order
    )

    if current_stop_order <= source_order:

        remaining_stops = selected_journey_stops

    else:

        remaining_stops = (
            destination_order - current_stop_order
        )

    remaining_fraction = (
        remaining_stops / selected_journey_stops
    )

    # Keep the fraction between 0 and 1
    remaining_fraction = max(
        0.0,
        min(1.0, remaining_fraction)
    )

    # ---------------------------------------------------------
    # 11. Calculate ETA to passenger's destination
    # ---------------------------------------------------------
    predicted_eta = (
        predicted_total_duration *
        remaining_fraction
    )

    predicted_eta = round(
        float(predicted_eta),
        2
    )

    return {
        "success": True,
        "bus_id": request.bus_id,
        "bus_number": bus_route[1],
        "route_id": request.route_id,
        "source_stop_id": request.source_stop_id,
        "destination_stop_id": request.destination_stop_id,
        "current_stop_order": current_stop_order,
        "current_stop": current_stop_name,
        "predicted_total_duration_minutes": round(
            predicted_total_duration,
            2
        ),
        "remaining_fraction": round(
            remaining_fraction,
            3
        ),
        "predicted_eta_minutes": predicted_eta,
        "message": "ETA to selected destination predicted successfully"
    }

@app.post("/recommend-bus")
def recommend_bus(request: RecommendationRequest):

    conn = get_connection()
    cursor = conn.cursor()

    # Find active buses serving the selected source and destination
    cursor.execute("""
        SELECT
            b.bus_id,
            b.bus_number,
            b.status,
            r.route_id,
            r.route_name,
            source_rs.stop_order AS source_order,
            destination_rs.stop_order AS destination_order,
            bl.latitude,
            bl.longitude,
            bl.updated_at
        FROM routes r
        JOIN route_stops source_rs
            ON r.route_id = source_rs.route_id
        JOIN route_stops destination_rs
            ON r.route_id = destination_rs.route_id
        JOIN buses b
            ON b.bus_name = r.route_name
        LEFT JOIN LATERAL (
            SELECT
                latitude,
                longitude,
                updated_at
            FROM bus_locations
            WHERE bus_id = b.bus_id
            ORDER BY updated_at DESC
            LIMIT 1
        ) bl ON TRUE
        WHERE source_rs.stop_id = %s
          AND destination_rs.stop_id = %s
          AND source_rs.stop_order < destination_rs.stop_order
          AND LOWER(b.status) = 'active'
        ORDER BY b.bus_id;
    """, (
        request.source_stop_id,
        request.destination_stop_id
    ))

    rows = cursor.fetchall()

    if not rows:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "No active bus found for the selected journey",
            "buses": []
        }

    buses = []

    for row in rows:

        bus_id = row[0]
        bus_number = row[1]
        status = row[2]
        route_id = row[3]
        route_name = row[4]
        source_order = row[5]
        destination_order = row[6]
        latitude = row[7]
        longitude = row[8]
        updated_at = row[9]

        # Check GPS availability
        location_available = (
            latitude is not None
            and longitude is not None
            and updated_at is not None
        )

        predicted_eta = None
        current_stop_order = None

        # --------------------------------------------------
        # STEP 1: Find current bus position on the route
        # --------------------------------------------------

        if location_available:

            cursor.execute("""
                SELECT
                    rs.stop_order,
                    s.latitude,
                    s.longitude
                FROM route_stops rs
                JOIN stops s
                    ON rs.stop_id = s.stop_id
                WHERE rs.route_id = %s
                ORDER BY rs.stop_order;
            """, (route_id,))

            route_stops = cursor.fetchall()

            if route_stops:

                # Find the route stop closest to the current
                # GPS position of the bus
                nearest_distance = None

                for stop in route_stops:

                    stop_order = stop[0]
                    stop_latitude = float(stop[1])
                    stop_longitude = float(stop[2])

                    distance = (
                        (float(latitude) - stop_latitude) ** 2
                        +
                        (float(longitude) - stop_longitude) ** 2
                    )

                    if (
                        nearest_distance is None
                        or distance < nearest_distance
                    ):
                        nearest_distance = distance
                        current_stop_order = stop_order

            # --------------------------------------------------
            # STEP 2: Random Forest prediction
            # --------------------------------------------------

            current_hour = datetime.now().hour

            input_data = pd.DataFrame([
                {
                    "bus_id": bus_id,
                    "route_id": route_id,
                    "departure_hour": current_hour,
                    "weather": "clear",
                    "traffic_level": "moderate"
                }
            ])

            prediction = eta_model.predict(input_data)[0]

            full_route_eta = float(prediction)

            # --------------------------------------------------
            # STEP 3: Calculate journey-specific ETA
            # --------------------------------------------------

            if route_stops:

                first_stop_order = route_stops[0][0]
                last_stop_order = route_stops[-1][0]

                # Total number of route segments
                full_route_segments = (
                    last_stop_order - first_stop_order
                )

                # Selected journey segments
                selected_journey_segments = (
                    destination_order - source_order
                )

                if (
                    full_route_segments > 0
                    and selected_journey_segments > 0
                ):

                    # Average time represented by one route segment
                    time_per_segment = (
                        full_route_eta / full_route_segments
                    )

                    # Bus has not reached passenger source yet
                    if (
                        current_stop_order is None
                        or current_stop_order < source_order
                    ):

                        remaining_segments = (
                            destination_order - source_order
                        )

                    # Bus is between passenger source
                    # and passenger destination
                    elif current_stop_order < destination_order:

                        remaining_segments = (
                            destination_order - current_stop_order
                        )

                    # Bus has already passed destination
                    else:

                        remaining_segments = 0

                    predicted_eta = round(
                        time_per_segment * remaining_segments,
                        2
                    )

                else:

                    predicted_eta = round(
                        full_route_eta,
                        2
                    )

        buses.append({
            "bus_id": bus_id,
            "bus_number": bus_number,
            "status": status,
            "route_id": route_id,
            "route_name": route_name,
            "source_stop_order": source_order,
            "destination_stop_order": destination_order,
            "current_stop_order": current_stop_order,
            "location_available": location_available,
            "latitude": (
                float(latitude)
                if latitude is not None
                else None
            ),
            "longitude": (
                float(longitude)
                if longitude is not None
                else None
            ),
            "updated_at": updated_at,
            "predicted_eta_minutes": predicted_eta
        })

    # --------------------------------------------------
    # STEP 4: Decision Engine
    # --------------------------------------------------

    eligible_buses = [
        bus
        for bus in buses
        if bus["location_available"]
        and bus["predicted_eta_minutes"] is not None
        and bus["predicted_eta_minutes"] > 0
    ]

    if not eligible_buses:

        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "No eligible bus with GPS location found",
            "buses": []
        }

    # Select bus with the lowest journey-specific ETA
    recommended_bus = min(
        eligible_buses,
        key=lambda bus: bus["predicted_eta_minutes"]
    )

    # Add recommendation information
    for bus in eligible_buses:

        if bus["bus_id"] == recommended_bus["bus_id"]:

            bus["recommended"] = True
            bus["reason"] = "Fastest estimated arrival"

        else:

            bus["recommended"] = False
            bus["reason"] = "Higher estimated arrival time"

    cursor.close()
    conn.close()

    return {
        "success": True,
        "source_stop_id": request.source_stop_id,
        "destination_stop_id": request.destination_stop_id,
        "recommended_bus": recommended_bus,
        "buses": eligible_buses
    }

@app.post("/book-ticket")
def book_ticket(request: TicketBookingRequest):

    conn = get_connection()
    cursor = conn.cursor()

    # Check that source and destination are different
    if request.source_stop_id == request.destination_stop_id:
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Source and destination cannot be the same"
        }

    # Check that the bus exists
    cursor.execute("""
        SELECT bus_id, bus_number
        FROM buses
        WHERE bus_id = %s;
    """, (request.bus_id,))

    bus = cursor.fetchone()

    if bus is None:
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Bus not found"
        }

    try:

        # Create ticket
        cursor.execute("""
            INSERT INTO tickets
            (
                user_id,
                bus_id,
                source_stop_id,
                destination_stop_id,
                fare,
                ticket_status
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING ticket_id, booking_time;
        """, (
            request.user_id,
            request.bus_id,
            request.source_stop_id,
            request.destination_stop_id,
            request.fare,
            "Booked"
        ))

        ticket = cursor.fetchone()

        ticket_id = ticket[0]
        booking_time = ticket[1]

        # Create payment record
        # Demo payment method: UPI
        cursor.execute("""
            INSERT INTO payments
            (
                ticket_id,
                amount,
                payment_method,
                payment_status
            )
            VALUES (%s, %s, %s, %s)
            RETURNING payment_id, payment_time;
        """, (
            ticket_id,
            request.fare,
            "UPI",
            "Success"
        ))

        payment = cursor.fetchone()

        payment_id = payment[0]
        payment_time = payment[1]

        # Save both ticket and payment together
        conn.commit()

    except Exception as e:

        # If anything fails, undo the ticket/payment operation
        conn.rollback()

        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Ticket booking failed"
        }

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Ticket booked successfully",

        "ticket_id": ticket_id,
        "booking_time": booking_time,

        "user_id": request.user_id,

        "bus_id": request.bus_id,
        "bus_number": bus[1],

        "source_stop_id": request.source_stop_id,
        "destination_stop_id": request.destination_stop_id,

        "fare": request.fare,
        "ticket_status": "Booked",

        "payment_id": payment_id,
        "payment_method": "UPI",
        "payment_status": "Success",
        "payment_time": payment_time
    }
@app.post("/create-razorpay-order")
def create_razorpay_order(request: CreateOrderRequest):

    conn = get_connection()
    cursor = conn.cursor()

    if request.source_stop_id == request.destination_stop_id:
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Source and destination cannot be the same"
        }

    cursor.execute("""
        SELECT bus_id, bus_number
        FROM buses
        WHERE bus_id = %s;
    """, (request.bus_id,))

    bus = cursor.fetchone()

    if bus is None:
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Bus not found"
        }

    if request.fare <= 0:
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Invalid fare"
        }

    amount_paise = int(round(request.fare * 100))

    try:
        order = razorpay_client.order.create(data={
            "amount": amount_paise,
            "currency": "INR",
            "payment_capture": 1,
        })
    except Exception:
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Unable to create Razorpay order"
        }

    try:
        cursor.execute("""
            INSERT INTO pending_orders
            (razorpay_order_id, user_id, bus_id, source_stop_id, destination_stop_id, fare)
            VALUES (%s, %s, %s, %s, %s, %s);
        """, (
            order["id"],
            request.user_id,
            request.bus_id,
            request.source_stop_id,
            request.destination_stop_id,
            request.fare
        ))
        conn.commit()
    except Exception:
        conn.rollback()
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Unable to start payment"
        }

    cursor.close()
    conn.close()

    return {
        "success": True,
        "order_id": order["id"],
        "amount": amount_paise,
        "currency": "INR",
        "key_id": RAZORPAY_KEY_ID,
        "bus_number": bus[1],
        "fare": request.fare
    }


@app.post("/verify-razorpay-payment")
def verify_razorpay_payment(request: VerifyPaymentRequest):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT user_id, bus_id, source_stop_id, destination_stop_id, fare
        FROM pending_orders
        WHERE razorpay_order_id = %s;
    """, (request.razorpay_order_id,))

    pending = cursor.fetchone()

    if pending is None:
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Order not found or already processed"
        }

    user_id, bus_id, source_stop_id, destination_stop_id, fare = pending

    try:
        razorpay_client.utility.verify_payment_signature({
            "razorpay_order_id": request.razorpay_order_id,
            "razorpay_payment_id": request.razorpay_payment_id,
            "razorpay_signature": request.razorpay_signature
        })
    except SignatureVerificationError:
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Payment verification failed"
        }

    cursor.execute("""
        SELECT bus_number FROM buses WHERE bus_id = %s;
    """, (bus_id,))
    bus = cursor.fetchone()

    try:
        cursor.execute("""
            INSERT INTO tickets
            (user_id, bus_id, source_stop_id, destination_stop_id, fare, ticket_status)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING ticket_id, booking_time;
        """, (
            user_id, bus_id, source_stop_id, destination_stop_id, fare, "Booked"
        ))

        ticket = cursor.fetchone()
        ticket_id = ticket[0]
        booking_time = ticket[1]

        cursor.execute("""
            INSERT INTO payments
            (ticket_id, amount, payment_method, payment_status,
             razorpay_order_id, razorpay_payment_id, razorpay_signature)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING payment_id, payment_time;
        """, (
            ticket_id,
            fare,
            "Razorpay",
            "Success",
            request.razorpay_order_id,
            request.razorpay_payment_id,
            request.razorpay_signature
        ))

        payment = cursor.fetchone()
        payment_id = payment[0]
        payment_time = payment[1]

        cursor.execute("""
            DELETE FROM pending_orders WHERE razorpay_order_id = %s;
        """, (request.razorpay_order_id,))

        conn.commit()

    except Exception:
        conn.rollback()
        cursor.close()
        conn.close()
        return {
            "success": False,
            "message": "Payment verified but ticket creation failed. Contact support."
        }

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Payment verified and ticket booked",
        "ticket_id": ticket_id,
        "booking_time": booking_time,
        "bus_id": bus_id,
        "bus_number": bus[0] if bus else None,
        "source_stop_id": source_stop_id,
        "destination_stop_id": destination_stop_id,
        "fare": fare,
        "ticket_status": "Booked",
        "payment_id": payment_id,
        "payment_method": "Razorpay",
        "payment_status": "Success",
        "razorpay_payment_id": request.razorpay_payment_id,
        "payment_time": payment_time
    }
@app.get("/ticket/{ticket_id}")
def get_ticket(ticket_id: int):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            t.ticket_id,
            u.full_name,
            b.bus_number,
            s1.stop_name AS source,
            s2.stop_name AS destination,
            t.fare,
            t.ticket_status,
            t.booking_time,

            p.payment_id,
            p.amount,
            p.payment_method,
            p.payment_status,
            p.payment_time,
            p.razorpay_payment_id

        FROM tickets t

        JOIN users u
            ON t.user_id = u.user_id

        JOIN buses b
            ON t.bus_id = b.bus_id

        JOIN stops s1
            ON t.source_stop_id = s1.stop_id

        JOIN stops s2
            ON t.destination_stop_id = s2.stop_id

        LEFT JOIN payments p
            ON t.ticket_id = p.ticket_id

        WHERE t.ticket_id = %s;
    """, (ticket_id,))

    row = cursor.fetchone()

    cursor.close()
    conn.close()

    if row is None:
        return {
            "success": False,
            "message": "Ticket not found"
        }

    return {
        "success": True,

        "ticket_id": row[0],
        "passenger": row[1],
        "bus_number": row[2],

        "source": row[3],
        "destination": row[4],

        "fare": float(row[5]) if row[5] is not None else 0,

        "ticket_status": row[6],
        "booking_time": row[7],

        "payment_id": row[8],
        "payment_amount": float(row[9]) if row[9] is not None else 0,
        "payment_method": row[10],
        "payment_status": row[11],
        "payment_time": row[12],
        "razorpay_payment_id": row[13]
    }

@app.post("/calculate-fare")
def calculate_fare(request: FareRequest):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            rs1.stop_order,
            rs2.stop_order
        FROM buses b
        JOIN routes r
            ON b.bus_name = r.route_name
        JOIN route_stops rs1
            ON r.route_id = rs1.route_id
        JOIN route_stops rs2
            ON r.route_id = rs2.route_id
        WHERE b.bus_id = %s
          AND rs1.stop_id = %s
          AND rs2.stop_id = %s
    """, (
        request.bus_id,
        request.source_stop_id,
        request.destination_stop_id
    ))

    row = cursor.fetchone()

    cursor.close()
    conn.close()

    if row is None:
        return {
            "success": False,
            "message": "Selected stops are not valid for this bus"
        }

    source_order = row[0]
    destination_order = row[1]

    if source_order >= destination_order:
        return {
            "success": False,
            "message": "Destination must be after the source stop"
        }

    stop_count = destination_order - source_order

    if stop_count == 1:
        fare = 15
    elif stop_count == 2:
        fare = 20
    elif stop_count == 3:
        fare = 25
    elif stop_count == 4:
        fare = 30
    elif stop_count == 5:
        fare = 35
    else:
        fare = 40

    return {
        "success": True,
        "bus_id": request.bus_id,
        "source_stop_id": request.source_stop_id,
        "destination_stop_id": request.destination_stop_id,
        "stop_count": stop_count,
        "fare": fare
    }

@app.post("/start-trip")
def start_trip(request: StartTripRequest):

    conn = get_connection()
    cursor = conn.cursor()

    # Check that the selected bus exists
    cursor.execute("""
        SELECT bus_id, bus_number
        FROM buses
        WHERE bus_id = %s;
    """, (request.bus_id,))

    bus = cursor.fetchone()

    if bus is None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Bus not found"
        }

    # Check that the selected route exists
    cursor.execute("""
        SELECT route_id, route_name
        FROM routes
        WHERE route_id = %s;
    """, (request.route_id,))

    route = cursor.fetchone()

    if route is None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Route not found"
        }

    # Check whether this bus is already running a trip
    cursor.execute("""
        SELECT trip_id
        FROM trip_history
        WHERE bus_id = %s
          AND arrival_time IS NULL
        ORDER BY trip_id DESC
        LIMIT 1;
    """, (request.bus_id,))

    active_trip = cursor.fetchone()

    if active_trip is not None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "This bus already has an active trip",
            "trip_id": active_trip[0]
        }

    # Create a new trip
    cursor.execute("""
        INSERT INTO trip_history
        (
            bus_id,
            route_id,
            travel_date,
            departure_time,
            weather,
            traffic_level
        )
        VALUES (%s, %s, CURRENT_DATE, CURRENT_TIME, %s, %s)
        RETURNING trip_id, travel_date, departure_time;
    """, (
        request.bus_id,
        request.route_id,
        request.weather,
        request.traffic_level
    ))

    trip = cursor.fetchone()

    # Mark bus as active
    cursor.execute("""
        UPDATE buses
        SET status = 'active'
        WHERE bus_id = %s;
    """, (request.bus_id,))

    conn.commit()

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Trip started successfully",
        "trip_id": trip[0],
        "bus_id": request.bus_id,
        "bus_number": bus[1],
        "route_id": request.route_id,
        "route_name": route[1],
        "travel_date": trip[1],
        "departure_time": trip[2],
        "status": "active"
    }


@app.post("/end-trip")
def end_trip(request: EndTripRequest):

    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Check whether the bus exists
        cursor.execute("""
            SELECT bus_id, bus_number
            FROM buses
            WHERE bus_id = %s;
        """, (request.bus_id,))

        bus = cursor.fetchone()

        if bus is None:
            return {
                "success": False,
                "message": "Bus not found"
            }

        # Find the active trip for this bus
        cursor.execute("""
            SELECT trip_id
            FROM trip_history
            WHERE bus_id = %s
              AND arrival_time IS NULL
            ORDER BY trip_id DESC
            LIMIT 1;
        """, (request.bus_id,))

        active_trip = cursor.fetchone()

        if active_trip is None:
            return {
                "success": False,
                "message": "No active trip found for this bus"
            }

        trip_id = active_trip[0]

        # End the active trip
        cursor.execute("""
            UPDATE trip_history
            SET arrival_time = CURRENT_TIME
            WHERE trip_id = %s;
        """, (trip_id,))

        # Mark the bus as available
        cursor.execute("""
            UPDATE buses
            SET status = 'active'
            WHERE bus_id = %s;
        """, (request.bus_id,))

        conn.commit()

        return {
            "success": True,
            "message": "Trip ended successfully",
            "trip_id": trip_id,
            "bus_id": request.bus_id,
            "bus_number": bus[1],
            "status": "completed"
        }

    except Exception as e:
        conn.rollback()

        return {
            "success": False,
            "message": str(e)
        }

    finally:
        cursor.close()
        conn.close()

@app.post("/add-bus")
def add_bus(request: AddBusRequest):

    conn = get_connection()
    cursor = conn.cursor()

    # Check whether the bus number already exists
    cursor.execute("""
        SELECT bus_id
        FROM buses
        WHERE bus_number = %s;
    """, (request.bus_number,))

    existing_bus = cursor.fetchone()

    if existing_bus is not None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Bus number already exists"
        }

    # Add the new bus
    cursor.execute("""
        INSERT INTO buses
        (
            bus_number,
            bus_name,
            capacity,
            status
        )
        VALUES (%s, %s, %s, %s)
        RETURNING bus_id, bus_number, bus_name, capacity, status;
    """, (
        request.bus_number,
        request.bus_name,
        request.capacity,
        "active"
    ))

    bus = cursor.fetchone()

    conn.commit()

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Bus added successfully",
        "bus_id": bus[0],
        "bus_number": bus[1],
        "bus_name": bus[2],
        "capacity": bus[3],
        "status": bus[4]
    }

@app.post("/add-route")
def add_route(request: AddRouteRequest):

    conn = get_connection()
    cursor = conn.cursor()

    # Check whether the route already exists
    cursor.execute("""
        SELECT route_id
        FROM routes
        WHERE route_name = %s;
    """, (request.route_name,))

    existing_route = cursor.fetchone()

    if existing_route is not None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Route already exists"
        }

    # Add the new route
    cursor.execute("""
        INSERT INTO routes
        (
            route_name,
            source,
            destination,
            distance_km
        )
        VALUES (%s, %s, %s, %s)
        RETURNING route_id, route_name, source, destination, distance_km;
    """, (
        request.route_name,
        request.source,
        request.destination,
        request.distance_km
    ))

    route = cursor.fetchone()

    conn.commit()

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Route added successfully",
        "route_id": route[0],
        "route_name": route[1],
        "source": route[2],
        "destination": route[3],
        "distance_km": float(route[4])
    }

@app.get("/operators")
def get_operators():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            user_id,
            full_name,
            email,
            phone,
            role,
            status
        FROM users
        WHERE role = 'operator'
        ORDER BY user_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    operators = []

    for row in rows:
        operators.append({
            "user_id": row[0],
            "full_name": row[1],
            "email": row[2],
            "phone": row[3],
            "role": row[4],
            "status": row[5]
        })

    return {
        "success": True,
        "operators": operators
    }

@app.put("/operator/{user_id}/status")
def update_operator_status(
    user_id: int,
    request: UpdateOperatorStatusRequest
):
    if request.status not in ["active", "inactive"]:
        return {
            "success": False,
            "message": "Status must be active or inactive"
        }

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT user_id, full_name, role
        FROM users
        WHERE user_id = %s
          AND role = 'operator';
    """, (user_id,))

    operator = cursor.fetchone()

    if operator is None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Operator not found"
        }

    cursor.execute("""
        UPDATE users
        SET status = %s
        WHERE user_id = %s
          AND role = 'operator'
        RETURNING user_id, full_name, email, role, status;
    """, (request.status, user_id))

    updated_operator = cursor.fetchone()

    conn.commit()

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Operator status updated successfully",
        "user_id": updated_operator[0],
        "full_name": updated_operator[1],
        "email": updated_operator[2],
        "role": updated_operator[3],
        "status": updated_operator[4]
    }

@app.put("/bus/{bus_id}/status")
def update_bus_status(
    bus_id: int,
    request: UpdateBusStatusRequest
):
    if request.status not in ["active", "inactive"]:
        return {
            "success": False,
            "message": "Status must be active or inactive"
        }

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT bus_id
        FROM buses
        WHERE bus_id = %s;
    """, (bus_id,))

    bus = cursor.fetchone()

    if bus is None:
        cursor.close()
        conn.close()

        return {
            "success": False,
            "message": "Bus not found"
        }

    cursor.execute("""
        UPDATE buses
        SET status = %s
        WHERE bus_id = %s
        RETURNING bus_id, bus_number, bus_name, status;
    """, (request.status, bus_id))

    updated_bus = cursor.fetchone()

    conn.commit()

    cursor.close()
    conn.close()

    return {
        "success": True,
        "message": "Bus status updated successfully",
        "bus_id": updated_bus[0],
        "bus_number": updated_bus[1],
        "bus_name": updated_bus[2],
        "status": updated_bus[3]
    }

@app.get("/admin/reports")
def get_admin_reports():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            (SELECT COUNT(*) FROM buses) AS total_buses,

            (SELECT COUNT(*)
             FROM buses
             WHERE status = 'active') AS active_buses,

            (SELECT COUNT(*) FROM routes) AS total_routes,

            (SELECT COUNT(*)
             FROM routes
             WHERE status = 'active') AS active_routes,

            (SELECT COUNT(*)
             FROM users
             WHERE role = 'operator') AS total_operators,

            (SELECT COUNT(*) FROM trip_history) AS total_trips;
    """)

    report = cursor.fetchone()

    cursor.close()
    conn.close()

    return {
        "success": True,
        "reports": {
            "total_buses": report[0],
            "active_buses": report[1],
            "total_routes": report[2],
            "active_routes": report[3],
            "total_operators": report[4],
            "total_trips": report[5]
        }
    }

@app.get("/operator/{operator_id}/buses")
def get_operator_buses(operator_id: int):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            b.bus_id,
            b.bus_number,
            b.bus_name,
            b.capacity,
            b.status,
            ba.assignment_id,
            ba.assigned_date

        FROM bus_assignment ba

        JOIN buses b
            ON ba.bus_id = b.bus_id

        WHERE ba.operator_id = %s

        ORDER BY ba.assigned_date DESC;
    """, (operator_id,))

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    buses = []

    for row in rows:
        buses.append({
            "bus_id": row[0],
            "bus_number": row[1],
            "bus_name": row[2],
            "capacity": row[3],
            "status": row[4],
            "assignment_id": row[5],
            "assigned_date": (
                row[6].isoformat()
                if row[6] is not None
                else None
            )
        })

    return {
        "success": True,
        "buses": buses
    }


from pydantic import BaseModel


class AddStopRequest(BaseModel):
    stop_name: str
    latitude: float
    longitude: float


@app.post("/admin/add-stop")
def add_stop(request: AddStopRequest):
    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Check whether a stop with the same name already exists
        cursor.execute(
            """
            SELECT stop_id
            FROM stops
            WHERE LOWER(stop_name) = LOWER(%s);
            """,
            (request.stop_name.strip(),)
        )

        existing_stop = cursor.fetchone()

        if existing_stop:
            return {
                "success": False,
                "message": "A stop with this name already exists"
            }

        # Insert the new bus stop
        cursor.execute(
            """
            INSERT INTO stops (
                stop_name,
                latitude,
                longitude
            )
            VALUES (%s, %s, %s)
            RETURNING stop_id;
            """,
            (
                request.stop_name.strip(),
                request.latitude,
                request.longitude
            )
        )

        new_stop_id = cursor.fetchone()[0]

        conn.commit()

        return {
            "success": True,
            "message": "Bus stop added successfully",
            "stop_id": new_stop_id
        }

    except Exception as e:
        conn.rollback()

        return {
            "success": False,
            "message": str(e)
        }

    finally:
        cursor.close()
        conn.close()


@app.post("/update-bus-location")
def update_bus_location(request: UpdateBusLocationRequest):
    conn = get_connection()
    cursor = conn.cursor()

    try:
        # Check whether the bus exists.
        cursor.execute(
            """
            SELECT bus_id
            FROM buses
            WHERE bus_id = %s;
            """,
            (request.bus_id,)
        )

        bus = cursor.fetchone()

        if bus is None:
            return {
                "success": False,
                "message": "Bus not found"
            }

        # Save the latest GPS location.
        cursor.execute(
            """
            INSERT INTO bus_locations (
                bus_id,
                latitude,
                longitude,
                speed,
                updated_at
            )
            VALUES (
                %s,
                %s,
                %s,
                %s,
                CURRENT_TIMESTAMP
            );
            """,
            (
                request.bus_id,
                request.latitude,
                request.longitude,
                request.speed
            )
        )

        conn.commit()

        return {
            "success": True,
            "message": "Bus location updated successfully"
        }

    except Exception as e:
        conn.rollback()

        return {
            "success": False,
            "message": f"Unable to update bus location: {str(e)}"
        }

    finally:
        cursor.close()
        conn.close()