#!/bin/bash
# Monitoring .NET API 5xx Alerts with OpenTelemetry, Prometheus, and Grafana
# Author: LinuxNetHelp (Prasanth Hole)

set -e

echo "=== Step 1: Update & install prerequisites ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget unzip curl apt-transport-https software-properties-common gnupg
sudo apt install -y libicu-dev libkrb5-3 zlib1g libssl-dev

echo "=== Step 2: Install .NET 9 SDK ==="
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH
./dotnet-install.sh --channel 9.0
echo 'export PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools' >> ~/.bashrc
source ~/.bashrc
dotnet --version

echo "=== Step 3: Create .NET Web API with OpenTelemetry ==="
mkdir -p MyLearningApp && cd MyLearningApp
export PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools

dotnet new web --no-https --force

# Add NuGet packages
dotnet add package OpenTelemetry.Extensions.Hosting
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package OpenTelemetry.Exporter.Prometheus.AspNetCore --prerelease
dotnet add package OpenTelemetry.Exporter.Console
dotnet add package OpenTelemetry.Instrumentation.Http
dotnet add package OpenTelemetry.Instrumentation.Runtime
dotnet add package Swashbuckle.AspNetCore
dotnet add package Microsoft.AspNetCore.OpenApi

# Replace Program.cs
cat > Program.cs << 'EOF'
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi.Models;
using OpenTelemetry.Resources;
using OpenTelemetry.Metrics;
using OpenTelemetry.Logs;

var builder = WebApplication.CreateBuilder(args);

// Logging
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole(o => {
    o.TimestampFormat = "[HH:mm:ss] ";
    o.SingleLine = true;
});

// OpenTelemetry
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService("MyLearningApp"))
    .WithMetrics(m => {
        m.AddAspNetCoreInstrumentation();
        m.AddHttpClientInstrumentation();
        m.AddRuntimeInstrumentation();
        m.AddPrometheusExporter();
    });

// Swagger
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c => {
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "MyLearningApp API", Version = "v1" });
});

var app = builder.Build();

app.UseOpenTelemetryPrometheusScrapingEndpoint();
app.UseSwagger();
app.UseSwaggerUI();

app.MapGet("/api/test/{input}", ([FromRoute] string input, ILogger<Program> logger) => {
    if (input.ToLower() == "success") {
        logger.LogInformation("Received success");
        return Results.Ok("200 OK");
    } else {
        logger.LogError("Received wrong input: {input}", input);
        return Results.Problem("500 Error", statusCode: 500);
    }
});

app.Run();
EOF

echo "=== Step 4: Run the API in background ==="
nohup dotnet run --urls "http://0.0.0.0:5000" > dotnet.log 2>&1 &

echo "=== Step 5: Install Prometheus ==="
cd ..
wget https://github.com/prometheus/prometheus/releases/download/v3.4.2/prometheus-3.4.2.linux-amd64.tar.gz
tar -xvf prometheus-3.4.2.linux-amd64.tar.gz
sudo mv prometheus-3.4.2.linux-amd64 /etc/prometheus

cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'dotnetapp'
    static_configs:
      - targets: ['localhost:5000']
EOF

nohup /etc/prometheus/prometheus --config.file=/etc/prometheus/prometheus.yml > prometheus.log 2>&1 &

echo "=== Step 6: Install Grafana ==="
sudo mkdir -p /etc/apt/keyrings/
curl -fsSL https://apt.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

if ! sudo apt update; then
  echo "APT repo failed, falling back to .deb install..."
  wget https://dl.grafana.com/oss/release/grafana_11.2.0_amd64.deb
  sudo apt install -y ./grafana_11.2.0_amd64.deb
else
  sudo apt install -y grafana
fi

sudo systemctl enable grafana-server
sudo systemctl restart grafana-server

echo "=== Setup complete ==="
echo "Swagger API:    http://<YOUR-IP>:5000/swagger"
echo "Prometheus:     http://<YOUR-IP>:9090"
echo "Grafana:        http://<YOUR-IP>:3000 (admin/admin)"
