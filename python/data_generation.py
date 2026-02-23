import pandas as pd
from faker import Faker
import random
from datetime import datetime
from datetime import date

fake = Faker()

# -------------------------
# Create user Table
# -------------------------

users= []

for i in range(20000):
    user= {
        "user_id":i+1,
        "name": fake.name(),
        "date_of_birth": fake.date_of_birth(minimum_age=18, maximum_age=65),
        "country" : fake.country(),
        "signup_date": fake.date_between(
        start_date='-5y',
        end_date=date.today())

    } 
    users.append(user)

df = pd.DataFrame(users)

df.to_csv("data/users.csv", index=False)

# -------------------------
# Create Plans Table
# -------------------------

plans = [
    {
        "plan_id": 1,
        "plan_name": "Mobile",
        "monthly_price": 149,
        "max_devices": 1
    },
    {
        "plan_id": 2,
        "plan_name": "Basic",
        "monthly_price": 199,
        "max_devices": 1
    },
    {
        "plan_id": 3,
        "plan_name": "Standard",
        "monthly_price": 499,
        "max_devices": 2
    },
    {
        "plan_id": 4,
        "plan_name": "Premium",
        "monthly_price": 649,
        "max_devices": 4
    }
]

plans_df = pd.DataFrame(plans)

print(plans_df)

plans_df.to_csv("data/plans.csv", index=False)

# -------------------------
# Create Subscriptions Table
# -------------------------

subscriptions = []

for i in range(1, 20001):

    start_date = fake.date_between(start_date='-3y', end_date='today')

    # 70% active, 30% churned
    is_active = random.randint(1, 100) <= 70

    if is_active:
        end_date = None
    else:
        end_date = fake.date_between(start_date=start_date, end_date='today')

    subscription = {
        "subscription_id": i,
        "user_id": i,
        "plan_id": random.randint(1, 4),
        "start_date": start_date,
        "end_date": end_date,
        "is_active": int(is_active)
    }

    subscriptions.append(subscription)

subscriptions_df = pd.DataFrame(subscriptions)

print(subscriptions_df.head())
print(subscriptions_df.shape)

subscriptions_df.to_csv("data/subscriptions.csv", index=False)

# -------------------------
# Create Payments Table
# -------------------------

payments = []
payment_id = 1

today = pd.Timestamp.today()

for _, sub in subscriptions_df.iterrows():

    user_id = sub["user_id"]
    subscription_id = sub["subscription_id"]
    plan_id = sub["plan_id"]
    start_date = pd.Timestamp(sub["start_date"])
    end_date = pd.Timestamp(sub["end_date"]) if pd.notna(sub["end_date"]) else None


    # Get plan price from plans_df
    plan_price = plans_df.loc[plans_df["plan_id"] == plan_id, "monthly_price"].values[0]

    current_date = start_date

    # Determine last billing date
    last_date = today if pd.isna(end_date) else pd.Timestamp(end_date)

    while current_date <= last_date:

        payment_status = "Success" if random.randint(1, 100) > 5 else "Failed"

        payment = {
            "payment_id": payment_id,
            "user_id": user_id,
            "subscription_id": subscription_id,
            "amount": plan_price,
            "payment_date": current_date,
            "payment_status": payment_status
        }

        payments.append(payment)
        payment_id += 1

        # Move to next month
        current_date = current_date + pd.DateOffset(months=1)

payments_df = pd.DataFrame(payments)

print(payments_df.head())
print(payments_df.shape)

payments_df.to_csv("data/payments.csv", index=False)


