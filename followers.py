import requests

username = "prathmesh_pro"  # <-- Tera username yaha dal

def get_followers(username):
    url = f"https://dev.to/api/followers/users?per_page=1000"
    headers = {
        "Accept": "application/json",
        "api-key": "p3Lzu2KKZh7C5hcaGnoG4UMz"  # API key optional hai, public data ke liye nahi chahiye
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        followers = response.json()

        # Filter followers who follow YOU
        matched = [f for f in followers if f.get("target_user", {}).get("username") == username]

        if not matched:
            print("No followers found (or API didn't return specific data).")
            return

        for f in matched:
            user = f.get("user", {})
            name = user.get("name", "Unknown")
            avatar = user.get("profile_image", "")
            print(f"👤 {name} — {avatar}")

    except requests.exceptions.RequestException as e:
        print(f"Error fetching data: {e}")

get_followers(username)
