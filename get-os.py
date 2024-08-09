from fabric import Connection
import pandas as pd

# List of hosts
hosts = [
    "a6000-3.wlcb"
]

# Function to get hardware info via SSH
def get_hardware_info(hostname):
    try:
        print(f"Connecting to {hostname}...")
        conn = Connection(host=hostname)

        # Get brand and model
        result = conn.run("sudo dmidecode -s system-manufacturer && sudo dmidecode -s system-product-name", hide=True)
        brand_model = result.stdout.strip().split('\n')
        brand = brand_model[0] if len(brand_model) > 0 else ""
        model = brand_model[1] if len(brand_model) > 1 else ""
        print(f"Brand: {brand}, Model: {model}")

        # Get GPU info
        result = conn.run("lspci | grep -i vga", hide=True)
        gpu_info = result.stdout.strip()
        print(f"GPU Info: {gpu_info}")

        # Get CPU info
        result = conn.run("lscpu", hide=True)
        cpu_info = result.stdout.strip()
        print(f"CPU Info: {cpu_info}")

        # Get Disk info
        result = conn.run("lsblk", hide=True)
        disk_info = result.stdout.strip()
        print(f"Disk Info: {disk_info}")

        return brand, model, gpu_info, cpu_info, disk_info

    except Exception as e:
        print(f"Failed to connect to {hostname}: {e}")
        return "", "", "", "", ""

# Create DataFrame
df = pd.DataFrame({
    "主机名": hosts,
    "品牌和型号": [""] * len(hosts),
    "GPU/CPU/硬盘型号": [""] * len(hosts),
    "GPU/CPU/硬盘数量": [""] * len(hosts),
    "上架时间": [""] * len(hosts),
    "机房位置": [""] * len(hosts)
})

# Fetch hardware info for each host
for index, row in df.iterrows():
    print(f"Fetching info for {row['主机名']}...")
    brand, model, gpu, cpu, disk = get_hardware_info(row["主机名"])
    if gpu:  # Only consider hosts with GPU
        df.at[index, "品牌和型号"] = f"{brand} {model}"
        df.at[index, "GPU/CPU/硬盘型号"] = f"{gpu} / {cpu} / {disk}"
        # Here you can add the logic to count GPU/CPU/Disk numbers if needed
        df.at[index, "GPU/CPU/硬盘数量"] = "数量"
    else:
        print(f"No GPU found for {row['主机名']}")

# Remove rows without GPU info
df = df[df["GPU/CPU/硬盘型号"].str.contains("vga", case=False, na=False)]

# Save to Markdown
df.to_markdown("server_info.md", index=False)
print("Markdown file saved as 'server_info.md'.")