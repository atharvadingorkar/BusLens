import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, r2_score


# --------------------------------------------------
# 1. Load training dataset
# --------------------------------------------------

df = pd.read_csv("eta_training_data.csv")

print("Training dataset loaded successfully!")
print(f"Total records: {len(df)}")
print()


# --------------------------------------------------
# 2. Select input features and target
# --------------------------------------------------

X = df[
    [
        "bus_id",
        "route_id",
        "departure_hour",
        "weather",
        "traffic_level"
    ]
]

y = df["travel_duration"]


# --------------------------------------------------
# 3. Define categorical and numerical features
# --------------------------------------------------

categorical_features = [
    "weather",
    "traffic_level"
]

numerical_features = [
    "bus_id",
    "route_id",
    "departure_hour"
]


# --------------------------------------------------
# 4. Preprocess categorical data
# --------------------------------------------------

preprocessor = ColumnTransformer(
    transformers=[
        (
            "categorical",
            OneHotEncoder(handle_unknown="ignore"),
            categorical_features
        ),
        (
            "numerical",
            "passthrough",
            numerical_features
        )
    ]
)


# --------------------------------------------------
# 5. Create Random Forest model
# --------------------------------------------------

random_forest = RandomForestRegressor(
    n_estimators=100,
    random_state=42,
    max_depth=10
)


# --------------------------------------------------
# 6. Create complete ML pipeline
# --------------------------------------------------

model = Pipeline(
    steps=[
        ("preprocessor", preprocessor),
        ("random_forest", random_forest)
    ]
)


# --------------------------------------------------
# 7. Split dataset
# --------------------------------------------------

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42
)


print("Dataset split completed.")
print(f"Training records: {len(X_train)}")
print(f"Testing records: {len(X_test)}")
print()


# --------------------------------------------------
# 8. Train Random Forest
# --------------------------------------------------

print("Training Random Forest ETA model...")

model.fit(X_train, y_train)

print("Model training completed!")
print()


# --------------------------------------------------
# 9. Make predictions
# --------------------------------------------------

predictions = model.predict(X_test)


# --------------------------------------------------
# 10. Evaluate model
# --------------------------------------------------

mae = mean_absolute_error(y_test, predictions)
r2 = r2_score(y_test, predictions)

print("----- MODEL PERFORMANCE -----")
print(f"Mean Absolute Error: {mae:.2f} minutes")
print(f"R2 Score: {r2:.2f}")
print()


# --------------------------------------------------
# 11. Test one example prediction
# --------------------------------------------------

sample_trip = pd.DataFrame(
    [
        {
            "bus_id": 1,
            "route_id": 1,
            "departure_hour": 9,
            "weather": "clear",
            "traffic_level": "moderate"
        }
    ]
)

predicted_eta = model.predict(sample_trip)[0]

print("----- SAMPLE ETA PREDICTION -----")
print(f"Bus ID: 1")
print(f"Route ID: 1")
print(f"Predicted Travel Time: {predicted_eta:.2f} minutes")
print()


# --------------------------------------------------
# 12. Save trained model
# --------------------------------------------------

joblib.dump(model, "eta_model.pkl")

print("ETA model saved successfully!")
print("File created: eta_model.pkl")