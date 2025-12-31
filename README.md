# Personal Expense Tracker

## Project Overview
**Personal Expense Tracker** is a Flutter mobile application for tracking personal finances. Users can add, view, and categorize their income and expenses. The app calculates total balance dynamically and provides a simple interface for managing finances.  

This project uses **Supabase** for backend database and authentication and **Riverpod** for state management.  

It is developed for submission as a job assignment.

---

## Tech Stack

### Frontend
- **Flutter** – Cross-platform mobile application development
- **Dart** – Programming language used in Flutter

### State Management
- **Riverpod** – Scalable and reactive state management

### Backend & Authentication
- **Supabase**
  - Authentication (Email & Password)
  - PostgreSQL Database
  - Secure session management

### Navigation
- **GoRouter** – Declarative routing and navigation

### Charts & Analytics
- **Syncfusion Flutter Charts** – Used for statistics and data visualization

### Development Tools
- **Git & GitHub** – Version control and source code management
- **Android Studio** – Development IDE




## Features
- Add, edit, and delete **expenses** and **income**.
- Categorize transactions.
- Real-time calculation of **total balance**, **total income**, and **total expenses**.
- Transaction filtering by **week, month, year**, or view all.
- Integrated **Supabase backend** for authentication and transaction storage.
- **Riverpod** state management for reactive UI updates.
- Clean and responsive **Flutter UI**.

---


## Project Structure and Code Components

## Project Structure

```text
lib/
├── main.dart
│
├── core/
│   ├── supabase_client.dart
│   └── router.dart
│
├── features/
│   └── auth/
│       ├── welcome_page.dart
│       ├── login_page.dart
│       └── signup_page.dart
│
├── models/
│   └── transaction_model.dart
│
├── providers/
│   └── transaction_provider.dart
│
├── pages/
│   ├── home_page.dart
│   ├── add_expense_page.dart
│   ├── add_income_page.dart
│   └── statistics_page.dart



## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/JISHNU376/PersonalExpenseTracker---Repo.git
cd PersonalExpenseTracker---Repo



