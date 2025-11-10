CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL, -- client, artisan, commercant
    is_blocked BOOLEAN DEFAULT FALSE, -- New column for user block status
    mfa_enabled BOOLEAN DEFAULT FALSE, -- Multifactor authentication enabled
    mfa_secret VARCHAR(255), -- Secret key for TOTP
    last_seen TIMESTAMP
);

CREATE TABLE IF NOT EXISTS client_profiles (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    nom_complet VARCHAR(255),
    sexe VARCHAR(50),
    location VARCHAR(255),
    telephone VARCHAR(50),
    photo_url VARCHAR(255),
    adresse TEXT
);

CREATE TABLE IF NOT EXISTS artisan_profiles (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    nom_complet VARCHAR(255),
    sexe VARCHAR(50),
    specialite VARCHAR(255),
    description TEXT,
    location VARCHAR(255),
    telephone VARCHAR(50),
    annees_experience INTEGER,
    siret VARCHAR(14),
    site_web VARCHAR(255),
    photo_url VARCHAR(255),
    document_verification_url VARCHAR(255),
    verification_status VARCHAR(50) DEFAULT 'not_verified',
    horaires_ouverture TEXT,
    langues_parlees TEXT[],
    assurance_professionnelle BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS commercant_profiles (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    nom_entreprise VARCHAR(255),
    sexe_contact VARCHAR(50),
    type_commerce VARCHAR(255),
    description TEXT,
    adresse VARCHAR(255),
    location VARCHAR(255),
    telephone VARCHAR(50),
    siret VARCHAR(14),
    site_web VARCHAR(255),
    horaires_ouverture VARCHAR(255),
    photo_url VARCHAR(255),
    document_verification_url VARCHAR(255),
    verification_status VARCHAR(50) DEFAULT 'not_verified',
    langues_parlees TEXT[],
    assurance_professionnelle BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES users(id),
    receiver_id INTEGER NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'sent', -- New column for message status
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS demandes (
    id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES users(id),
    artisan_id INTEGER NOT NULL REFERENCES users(id),
    service_ids INTEGER[],
    service_description TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., pending, accepted, declined, completed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    artisan_id INTEGER NOT NULL REFERENCES users(id),
    client_id INTEGER NOT NULL REFERENCES users(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS favorites (
    user_id INTEGER NOT NULL REFERENCES users(id),
    favorite_artisan_id INTEGER NOT NULL REFERENCES users(id),
    PRIMARY KEY (user_id, favorite_artisan_id)
);

CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    artisan_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS portfolio_items (
    id SERIAL PRIMARY KEY,
    artisan_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url VARCHAR(255) NOT NULL,
    caption VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    reporter_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    reported_message_id INTEGER REFERENCES messages(id) ON DELETE SET NULL,
    reported_review_id INTEGER REFERENCES reviews(id) ON DELETE SET NULL,
    reported_portfolio_item_id INTEGER REFERENCES portfolio_items(id) ON DELETE SET NULL,
    report_type VARCHAR(50) NOT NULL, -- e.g., 'user', 'message', 'review', 'portfolio_item'
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- e.g., 'pending', 'resolved', 'rejected'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by_admin_id INTEGER REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- User who performed the action
    action_type VARCHAR(255) NOT NULL, -- e.g., 'user_login', 'user_blocked', 'report_resolved'
    entity_type VARCHAR(255), -- e.g., 'user', 'report', 'profile'
    entity_id INTEGER, -- ID of the entity affected by the action
    details JSONB, -- Additional details about the action (e.g., old_value, new_value)
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'XOF',
    reason VARCHAR(255), -- New column for payment reason
    kkiapay_transaction_id VARCHAR(255) UNIQUE, -- Kkiapay's unique transaction ID
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'success', 'failed', 'canceled'
    payment_method VARCHAR(50), -- 'mobile_money', 'card', 'wave'
    transaction_details JSONB, -- Full Kkiapay response
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_type VARCHAR(50) NOT NULL, -- e.g., 'profile_boost_monthly', 'premium_access'
    start_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- 'active', 'canceled', 'expired'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
