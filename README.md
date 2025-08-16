# Monitoring .NET API 5xx Alerts with OpenTelemetry, Prometheus, and Grafana (Shell Script)

This project provides a **shell-script-based stack** to monitor a **.NET 9 minimal API** for **5xx errors** using:

* **OpenTelemetry** (Prometheus exporter)
* **Prometheus** (metrics scraping & storage)
* **Grafana** (dashboards & alerting)

Prepared by **LinuxNetHelp (Prasanth Hole)** for educational tutorials.

---

## 🚀 Prerequisites (Tested on Ubuntu 25.04)

* Ubuntu Server 25.04 (EC2, VM, or bare metal)
* `sudo` privileges
* Internet connectivity

---

## 🛠️ Setup Instructions

Run the setup script:

```bash
git clone https://github.com/LinuxNetHelp/dotnet-monitor-otel-prometheus-grafana-setup.git
chmod +x setup.sh
sudo ./setup.sh
```

This will:

1. Install **.NET 9 SDK**.
2. Create a **.NET 9 Web API** instrumented with OpenTelemetry.
3. Configure the API with a `/metrics` endpoint.
4. Install and start **Prometheus**.
5. Install and start **Grafana**.

---

## ✅ Step 1: Verify Prometheus Targets & Query Metrics

Open Prometheus in your browser:

```
http://<EC2-Public-IPv4-Address>:9090
```

* Go to **Status → Targets** → you should see `dotnetapp` with state **UP**.
* Go to **Graph**, try querying:

```
http_server_request_duration_seconds_count
```

Click **Execute** to see metric results.

---

## ✅ Step 2: Configure Grafana Data Source

Open Grafana:

```
http://<EC2-Public-IPv4-Address>:3000
```

* Default login: `admin / admin` (change after first login).
* Go to **Connections → Data Sources**.
* Add new **Prometheus** datasource.
* Set URL:

```
http://<EC2-Public-IPv4-Address>:9090
```

* Click **Save & Test** → should show: *Successfully queried the Prometheus API*.

---

## ✅ Step 3: Create Grafana Dashboard

* Click **+ (Create)** → **New Dashboard**.
* Click **Add Visualization**.
* Select **Prometheus** as data source.
* Choose **Time series** visualization.
* Enter PromQL query:

```promql
rate(http_server_request_duration_seconds_count[1m])
```

* Click **Run queries**.
* Save dashboard → name it **.NET API Monitoring**.

---

## 🌐 URLs

* **.NET API (Swagger):** [http://localhost:5000/swagger](http://localhost:5000/swagger)
* **Prometheus:** [http://localhost:9090](http://localhost:9090)
* **Grafana:** [http://localhost:3000](http://localhost:3000) (admin / admin)
* **Metrics Endpoint:** [http://localhost:5000/metrics](http://localhost:5000/metrics)

---

## ⚙️ How It Works

1. The API is instrumented with **OpenTelemetry** and exposes `/metrics`.
2. **Prometheus** scrapes metrics from `localhost:5000/metrics`.
3. **Grafana** visualizes metrics and allows creating alerts.

---

## 📊 PromQL Examples

* **5xx Error Rate (last 1 minute):**

```promql
sum by(job) (rate(http_server_request_duration_seconds_count{status_code=~"5.."}[1m]))
```

* **Total Request Rate:**

```promql
rate(http_server_request_duration_seconds_count[1m])
```

---

## 🧪 Test the API

* `GET /api/test/success` → Returns **200 OK**.
* `GET /api/test/anything-else` → Returns **500 Internal Server Error**.

---

## 📺 Credits

Prepared for **LinuxNetHelp YouTube tutorials**.
👉 Watch tutorials here: [https://www.youtube.com/@LinuxNetHelp](https://www.youtube.com/watch?v=vtiPY78G2x8&ab_channel=LinuxNetHelp)

...
**License:** MIT

---
