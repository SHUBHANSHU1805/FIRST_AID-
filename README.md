FirstAid+ — MVP 
FirstAid+ is an AI-powered mobile emergency response app that provides instant guidance, alerts contacts, and helps users respond to medical emergencies quickly.

Goal:

Reduce response time in emergency situations.

Core MVP Features

You only need 4 working features.

1️⃣ Panic Button System

Your panic button triggers emergency actions.

When pressed:

• Get GPS location
• Send SMS to emergency contact
• Call ambulance

Flutter packages:

geolocator
url_launcher
flutter_sms

Flow:

User presses panic
      ↓
Get current location
      ↓
Send emergency SMS
      ↓
Call emergency number

Example SMS:

Emergency! I may need help.
My location:
https://maps.google.com/?q=lat,long
2️⃣ Voice Emergency Detection

User taps:

Describe Emergency

User says:

"Someone fainted"

The app:

• converts speech → text
• classifies emergency

Example output:

Emergency detected: Fainting
Suggested action: Lay person flat and elevate legs.

Flutter package:

speech_to_text
3️⃣ Emergency First Aid Guide

Each emergency chip opens step-by-step instructions.

Example:

Heart Attack

Steps shown:

1. Call emergency services
2. Help person sit down
3. Loosen tight clothing
4. Give aspirin if available

This can be stored locally as JSON.

Example:

{
 "heart_attack": [
   "Call ambulance immediately",
   "Help the person sit down",
   "Loosen tight clothing"
 ]
}
4️⃣ Share Location Feature

Pressing:

Share Location

sends location to emergency contact.

Flow:

Get GPS
     ↓
Generate map link
     ↓
Send SMS
App Screens (MVP)

Your app should have 4 screens.

1️⃣ Splash Screen

Already done.

Features:

• Lottie animation
• app branding

2️⃣ Emergency Dashboard

Already built.

Contains:

Panic Button
Describe Emergency
Scan Situation
Call Ambulance
Share Location
3️⃣ Emergency Guide Screen

Shows:

Emergency type
Step-by-step instructions

Example UI:

Emergency: Burn

Step 1: Cool burn with water
Step 2: Remove tight items
Step 3: Cover with clean cloth
4️⃣ Emergency Contacts Screen

User can add:

Mom
Friend
Doctor

These contacts receive panic alerts.

Project Architecture

Use this structure:

lib
 ├── main.dart
 ├── screens
 │     ├── splash_screen.dart
 │     ├── home_screen.dart
 │     ├── guide_screen.dart
 │     └── contacts_screen.dart
 │
 ├── services
 │     ├── location_service.dart
 │     ├── sms_service.dart
 │     └── speech_service.dart
 │
 ├── models
 │     └── emergency_model.dart
 │
 └── data
       emergency_guides.json

This looks professional on GitHub.

Tech Stack
Frontend

Flutter

Device APIs

• GPS
• microphone
• phone dialer

Packages
speech_to_text
geolocator
url_launcher
flutter_sms
lottie
Resume Description

You can write this:

FirstAid+ — AI Emergency Response App

Developed an AI-powered emergency response mobile application using Flutter that enables users to trigger emergency alerts, share real-time location, and receive first-aid guidance. Implemented voice-based emergency detection, GPS location tracking, and automated SMS alerts to emergency contacts to reduce response time during critical situations.

Tech stack:

Flutter • Dart • Speech Recognition • GPS APIs • Mobile AI
