# Use an official lightweight Python base image
FROM python:3.11-slim

# Set working directory inside the container
WORKDIR /app

# Install system dependencies for OpenCV (libGL)
 RUN apt-get update && apt-get install -y \
     libgl1 \
     libglib2.0-0 \
   && rm -rf /var/lib/apt/lists/*

# Copy only necessary files
COPY app.py .
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Command to run the app
CMD ["python", "app.py"]

