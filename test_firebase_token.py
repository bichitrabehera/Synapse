#!/usr/bin/env python3
"""
Test script to verify Firebase ID token validation
Run this on your backend server to debug token verification issues
"""

import os
import asyncio
import firebase_admin
from firebase_admin import auth, credentials
import json
from datetime import datetime

def initialize_firebase():
    """Initialize Firebase Admin SDK with environment variables"""
    if not firebase_admin._apps:
        firebase_config = {
            "type": os.getenv("FIREBASE_TYPE"),
            "project_id": os.getenv("FIREBASE_PROJECT_ID"),
            "private_key_id": os.getenv("FIREBASE_PRIVATE_KEY_ID"),
            "private_key": os.getenv("FIREBASE_PRIVATE_KEY").replace('\\n', '\n') if os.getenv("FIREBASE_PRIVATE_KEY") else None,
            "client_email": os.getenv("FIREBASE_CLIENT_EMAIL"),
            "client_id": os.getenv("FIREBASE_CLIENT_ID"),
            "auth_uri": os.getenv("FIREBASE_AUTH_URI"),
            "token_uri": os.getenv("FIREBASE_TOKEN_URI"),
            "auth_provider_x509_cert_url": os.getenv("FIREBASE_AUTH_PROVIDER_CERT_URL"),
            "client_x509_cert_url": os.getenv("FIREBASE_CLIENT_CERT_URL")
        }

        print("🔧 Initializing Firebase Admin SDK...")
        print(f"📋 Project ID: {firebase_config['project_id']}")
        print(f"📧 Client Email: {firebase_config['client_email']}")

        try:
            cred = credentials.Certificate(firebase_config)
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin SDK initialized successfully")
        except Exception as e:
            print(f"❌ Firebase initialization failed: {e}")
            return False
    else:
        print("ℹ️ Firebase Admin SDK already initialized")
    return True

async def verify_id_token(token: str):
    """Verify Firebase ID token asynchronously"""
    loop = asyncio.get_event_loop()
    try:
        print(f"🔍 Verifying token: {token[:50]}...")
        decoded_token = await loop.run_in_executor(None, auth.verify_id_token, token)
        print("✅ Token verified successfully!")
        print(f"👤 User ID: {decoded_token['uid']}")
        print(f"📧 Email: {decoded_token.get('email', 'N/A')}")
        print(f"⏰ Issued at: {datetime.fromtimestamp(decoded_token['iat'])}")
        print(f"⏰ Expires at: {datetime.fromtimestamp(decoded_token['exp'])}")
        return decoded_token
    except auth.ExpiredIdTokenError:
        print("❌ Token expired")
        raise
    except auth.InvalidIdTokenError as e:
        print(f"❌ Invalid token: {e}")
        raise
    except Exception as e:
        print(f"❌ Token verification failed: {e}")
        raise

def check_environment_variables():
    """Check if all required environment variables are set"""
    required_vars = [
        "FIREBASE_TYPE",
        "FIREBASE_PROJECT_ID",
        "FIREBASE_PRIVATE_KEY_ID",
        "FIREBASE_PRIVATE_KEY",
        "FIREBASE_CLIENT_EMAIL",
        "FIREBASE_CLIENT_ID",
        "FIREBASE_AUTH_URI",
        "FIREBASE_TOKEN_URI",
        "FIREBASE_AUTH_PROVIDER_CERT_URL",
        "FIREBASE_CLIENT_CERT_URL"
    ]

    print("🔍 Checking environment variables...")
    missing_vars = []
    for var in required_vars:
        value = os.getenv(var)
        if value:
            print(f"✅ {var}: {value[:50]}..." if len(value) > 50 else f"✅ {var}: {value}")
        else:
            print(f"❌ {var}: NOT SET")
            missing_vars.append(var)

    if missing_vars:
        print(f"\n❌ Missing environment variables: {missing_vars}")
        return False
    else:
        print("\n✅ All environment variables are set")
        return True

async def main():
    print("🚀 Firebase Token Verification Test")
    print("=" * 50)

    # Check environment variables
    if not check_environment_variables():
        print("❌ Cannot proceed without environment variables")
        return

    # Initialize Firebase
    if not initialize_firebase():
        print("❌ Cannot proceed without Firebase initialization")
        return

    # Test token verification
    print("\n" + "=" * 50)
    print("🔑 Token Verification Test")
    print("=" * 50)

    # You can paste your token here for testing
    test_token = input("📝 Paste your Firebase ID token here (or press Enter to skip): ").strip()

    if test_token:
        try:
            await verify_id_token(test_token)
        except Exception as e:
            print(f"❌ Token verification failed: {e}")
    else:
        print("ℹ️ No token provided. You can test manually by:")
        print("1. Get a Firebase ID token from your Flutter app")
        print("2. Run this script again and paste the token")
        print("3. Or modify the script to hardcode a test token")

    print("\n" + "=" * 50)
    print("📋 Next Steps:")
    print("1. If token verification fails, check Firebase project configuration")
    print("2. Ensure client and server use the same Firebase project")
    print("3. Verify system clock is synchronized (NTP)")
    print("4. Check Firebase Admin SDK version compatibility")

if __name__ == "__main__":
    asyncio.run(main())
