#!/usr/bin/env python3
"""Small read-only system-monitor helper for a Wingpanel indicator."""
from pathlib import Path
import time


def hwmon_nodes():
    root = Path("/sys/class/hwmon")
    try:
        nodes = list(root.glob("hwmon*"))
    except OSError:
        return []
    result = []
    for node in nodes:
        try:
            name = (node / "name").read_text().strip().lower()
            result.append((name, node))
        except (OSError, ValueError):
            continue
    return result


def cpu_temperature():
    for name, node in hwmon_nodes():
        if name != "coretemp":
            continue
        for label_path in node.glob("temp*_label"):
            try:
                if label_path.read_text().strip() != "Package id 0":
                    continue
                raw = (node / label_path.name.replace("_label", "_input")).read_text().strip()
                value = int(raw) / 1000
                if -20 < value < 120:
                    return round(value)
            except (OSError, ValueError):
                continue
    return None


def fan_rpm():
    for node in Path("/sys/devices/platform").glob("applesmc.*/fan1_input"):
        try:
            rpm = int(node.read_text().strip())
            if 0 <= rpm <= 20000:
                return rpm
        except (OSError, ValueError):
            continue
    return None


def cpu_sample():
    fields = Path("/proc/stat").read_text().splitlines()[0].split()
    if fields[0] != "cpu" or len(fields) < 5:
        raise ValueError("cpu aggregate unavailable")
    # First eight fields avoid guest times counted twice in user/nice.
    values = [int(value) for value in fields[1:9]]
    total = sum(values)
    idle = values[3] + (values[4] if len(values) > 4 else 0)
    return total, idle


def cpu_percent():
    try:
        total1, idle1 = cpu_sample()
        time.sleep(0.2)
        total2, idle2 = cpu_sample()
        delta = total2 - total1
        if delta <= 0:
            return None
        return round(max(0, min(100, 100 * (1 - (idle2 - idle1) / delta))))
    except (OSError, ValueError, IndexError):
        return None


def main():
    temp = cpu_temperature()
    load = cpu_percent()
    rpm = fan_rpm()
    temp_label = f"{temp} °C" if temp is not None else "— °C"
    load_label = f"{load} %" if load is not None else "— %"
    rpm_label = f"{rpm} RPM" if rpm is not None else "— RPM"
    print(f"CPU {temp_label} | {load_label} | {rpm_label}")


if __name__ == "__main__":
    main()

