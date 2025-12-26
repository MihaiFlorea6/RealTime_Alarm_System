import streamlit as st
import serial
import time
import pandas as pd
from datetime import datetime

#Configuaration
SERIAL_PORT = "COM9"
BAUD_RATE = 9600
REFRESH_TIME = 3

st.set_page_config(page_title="Alarm System Dashboard", layout="wide")

st.title("Alarm System Dashboard - Real-Time Monitor")
st.markdown("---")

#Initialize Session State for logs
if "logs" not in st.session_state:
    st.session_state.logs = []
if "last_status" not in st.session_state:
    st.session_state.last_status = None

if "serial" not in st.session_state:
    try:
        st.session_state.serial = serial.Serial(port=SERIAL_PORT, baudrate=BAUD_RATE, timeout=1)
        time.sleep(2)
        st.session_state.serial.reset_input_buffer()
        st.success(f"Connected to Basys 3 on {SERIAL_PORT}")
    except Exception as e:
        st.error(f"Connection Error: {e}")
        st.stop()

ser = st.session_state.serial

#Layout: Status Card and Log Table
col1, col2 = st.columns([1, 2])

with col1:
    st.subheader("System Status")
    status_placeholder = st.empty()
    status_placeholder.info("Waiting for data...")

with col2:
    st.subheader("Access History Log")
    log_placeholder = st.empty()

#Serial Communication Logic
if ser.in_waiting > 0:
    try:
            raw_data =  ser.read_until(b";").decode("ascii", errors="ignore").strip()

            if raw_data.startswith("STATUS:") and raw_data.endswith(";"):
                print(f"Received: {raw_data}")

                status_value = raw_data.replace("STATUS:", "").replace(";", "")
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

                #Update UI based on status
                if status_value == "OPEN":
                    status_placeholder.success(f" ACCESS GRANTED ({timestamp})")
                    st.session_state.logs.insert(0, {"Time": timestamp, "Event": "Unlock Success", "Type": "SUCCESS"})
                elif status_value == "WRONG":
                    status_placeholder.warning(f" WRONG PIN ({timestamp})")
                    st.session_state.logs.insert(0, {"Time": timestamp, "Event": "Incorrect PIN Attempt", "Type": "WARNING"})
                elif status_value == "LOCK":
                    status_placeholder.error(f" SYSTEM LOCKED ({timestamp})")
                    st.session_state.logs.insert(0, {"Time": timestamp, "Event": "Failed Attempts Limit", "Type": "ALARM"})

    except Exception as e:
            st.error(f"Read error: {e}")

#Update History Table
if st.session_state.logs:
    df = pd.DataFrame(st.session_state.logs)
    log_placeholder.table(df)

#Auto-refresh
time.sleep(REFRESH_TIME)
st.rerun()

