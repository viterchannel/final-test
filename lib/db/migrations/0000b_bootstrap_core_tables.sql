-- Bootstrap migration: Creates all core tables that ALTER TABLE migrations depend on.
-- Uses CREATE TABLE IF NOT EXISTS everywhere so it is safe on existing databases.
-- This file sorts between 0000 and 0001 alphabetically, ensuring it runs second.

-- ─── admin_accounts ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_accounts (
  id                    text PRIMARY KEY,
  name                  text NOT NULL,
  username              text UNIQUE,
  email                 text,
  secret                text NOT NULL UNIQUE,
  role                  text NOT NULL DEFAULT 'manager',
  permissions           text NOT NULL DEFAULT '',
  is_active             boolean NOT NULL DEFAULT true,
  totp_secret           text,
  totp_enabled          boolean NOT NULL DEFAULT false,
  language              text DEFAULT 'en',
  must_change_password  boolean NOT NULL DEFAULT false,
  password_changed_at   timestamp,
  default_credentials   boolean NOT NULL DEFAULT false,
  last_login_at         timestamp,
  created_at            timestamp NOT NULL DEFAULT now()
);

-- ─── admin_sessions ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_sessions (
  id                  text PRIMARY KEY,
  admin_id            text NOT NULL REFERENCES admin_accounts(id) ON DELETE CASCADE,
  refresh_token_hash  text NOT NULL,
  ip                  varchar(45) NOT NULL,
  user_agent          text,
  csrf_token_hash     text,
  created_at          timestamp NOT NULL DEFAULT now(),
  expires_at          timestamp NOT NULL,
  last_used_at        timestamp DEFAULT now(),
  revoked_at          timestamp
);

-- ─── admin_audit_log ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_audit_log (
  id          text PRIMARY KEY,
  admin_id    text REFERENCES admin_accounts(id) ON DELETE SET NULL,
  action      text NOT NULL,
  ip          text,
  user_agent  text,
  metadata    text,
  created_at  timestamp NOT NULL DEFAULT now()
);

-- ─── rate_limits ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rate_limits (
  key          text PRIMARY KEY,
  attempts     integer NOT NULL DEFAULT 0,
  locked_until timestamp,
  window_start timestamp NOT NULL DEFAULT now(),
  updated_at   timestamp NOT NULL DEFAULT now()
);

-- ─── products ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id                    text PRIMARY KEY,
  name                  text NOT NULL,
  description           text,
  price                 decimal(10,2) NOT NULL,
  original_price        decimal(10,2),
  category              text NOT NULL,
  type                  text NOT NULL DEFAULT 'mart',
  image                 text,
  images                text[],
  video_url             text,
  vendor_id             text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vendor_name           text,
  rating                decimal(3,1) DEFAULT '4.0',
  review_count          integer DEFAULT 0,
  in_stock              boolean NOT NULL DEFAULT true,
  stock                 integer,
  unit                  text,
  delivery_time         text,
  deal_expires_at       timestamp,
  approval_status       text NOT NULL DEFAULT 'approved',
  low_stock_threshold   integer,
  max_quantity_per_order integer,
  back_in_stock_notify  boolean,
  created_at            timestamp NOT NULL DEFAULT now(),
  updated_at            timestamp NOT NULL DEFAULT now(),
  CONSTRAINT products_price_positive CHECK (price > 0)
);
CREATE INDEX IF NOT EXISTS products_vendor_id_idx   ON products (vendor_id);
CREATE INDEX IF NOT EXISTS products_category_idx    ON products (category);
CREATE INDEX IF NOT EXISTS products_in_stock_idx    ON products (in_stock);
CREATE INDEX IF NOT EXISTS products_type_idx        ON products (type);
CREATE INDEX IF NOT EXISTS products_name_idx        ON products (name);
CREATE INDEX IF NOT EXISTS products_price_idx       ON products (price);

-- ─── product_variants ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS product_variants (
  id             text PRIMARY KEY,
  product_id     text NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  label          text NOT NULL,
  type           text NOT NULL DEFAULT 'size',
  price          decimal(10,2) NOT NULL,
  original_price decimal(10,2),
  sku            text,
  stock          integer,
  in_stock       boolean NOT NULL DEFAULT true,
  sort_order     integer NOT NULL DEFAULT 0,
  attributes     text,
  created_at     timestamp NOT NULL DEFAULT now(),
  updated_at     timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS product_variants_product_id_idx ON product_variants (product_id);

-- ─── orders ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id                text PRIMARY KEY,
  user_id           text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type              text NOT NULL,
  items             json NOT NULL,
  status            text NOT NULL DEFAULT 'pending',
  total             decimal(10,2) NOT NULL,
  delivery_address  text,
  payment_method    text NOT NULL,
  rider_id          text REFERENCES users(id) ON DELETE SET NULL,
  rider_name        text,
  rider_phone       text,
  vendor_id         text REFERENCES users(id) ON DELETE SET NULL,
  estimated_time    text,
  proof_photo_url   text,
  txn_ref           text,
  payment_status    text DEFAULT 'pending',
  refunded_at       timestamp,
  refunded_amount   decimal(10,2),
  assigned_rider_id text REFERENCES users(id) ON DELETE SET NULL,
  assigned_at       timestamp,
  customer_lat      decimal(10,7),
  customer_lng      decimal(10,7),
  gps_accuracy      double precision,
  gps_mismatch      boolean DEFAULT false,
  delivery_lat      decimal(10,7),
  delivery_lng      decimal(10,7),
  created_at        timestamp NOT NULL DEFAULT now(),
  updated_at        timestamp NOT NULL DEFAULT now(),
  CONSTRAINT orders_total_non_negative CHECK (total >= 0)
);
CREATE INDEX IF NOT EXISTS orders_user_id_idx           ON orders (user_id);
CREATE INDEX IF NOT EXISTS orders_rider_id_idx          ON orders (rider_id);
CREATE INDEX IF NOT EXISTS orders_vendor_id_idx         ON orders (vendor_id);
CREATE INDEX IF NOT EXISTS orders_status_idx            ON orders (status);
CREATE INDEX IF NOT EXISTS orders_created_at_idx        ON orders (created_at);
CREATE INDEX IF NOT EXISTS orders_assigned_rider_id_idx ON orders (assigned_rider_id);

-- ─── pharmacy_orders ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pharmacy_orders (
  id                 text PRIMARY KEY,
  user_id            text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rider_id           text REFERENCES users(id) ON DELETE SET NULL,
  items              json NOT NULL,
  prescription_note  text,
  delivery_address   text NOT NULL,
  contact_phone      text NOT NULL,
  total              decimal(10,2) NOT NULL,
  payment_method     text NOT NULL,
  status             text NOT NULL DEFAULT 'pending',
  estimated_time     text DEFAULT '25-40 min',
  created_at         timestamp NOT NULL DEFAULT now(),
  updated_at         timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS pharmacy_orders_user_id_idx    ON pharmacy_orders (user_id);
CREATE INDEX IF NOT EXISTS pharmacy_orders_rider_id_idx   ON pharmacy_orders (rider_id);
CREATE INDEX IF NOT EXISTS pharmacy_orders_status_idx     ON pharmacy_orders (status);
CREATE INDEX IF NOT EXISTS pharmacy_orders_created_at_idx ON pharmacy_orders (created_at);

-- ─── rides ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rides (
  id                  text PRIMARY KEY,
  user_id             text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type                text NOT NULL,
  status              text NOT NULL DEFAULT 'searching',
  pickup_address      text NOT NULL,
  drop_address        text NOT NULL,
  pickup_lat          decimal(10,6),
  pickup_lng          decimal(10,6),
  drop_lat            decimal(10,6),
  drop_lng            decimal(10,6),
  fare                decimal(10,2) NOT NULL,
  distance            decimal(10,2) NOT NULL,
  rider_id            text REFERENCES users(id) ON DELETE SET NULL,
  rider_name          text,
  rider_phone         text,
  payment_method      text NOT NULL,
  offered_fare        decimal(10,2),
  counter_fare        decimal(10,2),
  bargain_status      text,
  bargain_rounds      integer DEFAULT 0,
  bargain_note        text,
  cancellation_reason text,
  dispatched_rider_id text REFERENCES users(id) ON DELETE SET NULL,
  dispatch_attempts   jsonb DEFAULT '[]',
  dispatch_loop_count integer DEFAULT 0,
  dispatched_at       timestamp,
  expires_at          timestamp,
  trip_otp            text,
  otp_verified        boolean NOT NULL DEFAULT false,
  is_parcel           boolean NOT NULL DEFAULT false,
  receiver_name       text,
  receiver_phone      text,
  package_type        text,
  is_scheduled        boolean NOT NULL DEFAULT false,
  scheduled_at        timestamp,
  stops               jsonb DEFAULT null,
  is_pool_ride        boolean NOT NULL DEFAULT false,
  pool_group_id       text,
  accepted_at         timestamp,
  arrived_at          timestamp,
  started_at          timestamp,
  completed_at        timestamp,
  cancelled_at        timestamp,
  refunded_at         timestamp,
  created_at          timestamp NOT NULL DEFAULT now(),
  updated_at          timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS rides_user_id_idx    ON rides (user_id);
CREATE INDEX IF NOT EXISTS rides_rider_id_idx   ON rides (rider_id);
CREATE INDEX IF NOT EXISTS rides_status_idx     ON rides (status);
CREATE INDEX IF NOT EXISTS rides_created_at_idx ON rides (created_at);

-- ─── ride_bids ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ride_bids (
  id          text PRIMARY KEY,
  ride_id     text NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  rider_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rider_name  text NOT NULL,
  rider_phone text,
  fare        decimal(10,2) NOT NULL,
  note        text,
  status      text NOT NULL DEFAULT 'pending',
  expires_at  timestamp NOT NULL,
  created_at  timestamp NOT NULL DEFAULT now(),
  updated_at  timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ride_bids_ride_rider_uidx ON ride_bids (ride_id, rider_id);
CREATE INDEX IF NOT EXISTS ride_bids_ride_id_idx   ON ride_bids (ride_id);
CREATE INDEX IF NOT EXISTS ride_bids_rider_id_idx  ON ride_bids (rider_id);
CREATE INDEX IF NOT EXISTS ride_bids_status_idx    ON ride_bids (status);
CREATE INDEX IF NOT EXISTS ride_bids_expires_at_idx ON ride_bids (expires_at);

-- ─── wallet_transactions ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id             text PRIMARY KEY,
  user_id        text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type           text NOT NULL,
  amount         decimal(10,2) NOT NULL,
  description    text NOT NULL,
  reference      text,
  payment_method text,
  created_at     timestamp NOT NULL DEFAULT now(),
  CONSTRAINT wallet_txn_amount_non_negative CHECK (amount >= 0)
);
CREATE INDEX IF NOT EXISTS wallet_txn_user_id_idx    ON wallet_transactions (user_id);
CREATE INDEX IF NOT EXISTS wallet_txn_created_at_idx ON wallet_transactions (created_at);
CREATE INDEX IF NOT EXISTS wallet_txn_reference_idx  ON wallet_transactions (reference);

-- ─── reviews ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id               text PRIMARY KEY,
  order_id         text,
  user_id          text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vendor_id        text REFERENCES users(id) ON DELETE SET NULL,
  rider_id         text REFERENCES users(id) ON DELETE SET NULL,
  order_type       text NOT NULL,
  rating           integer NOT NULL,
  rider_rating     integer,
  comment          text,
  photos           text[],
  product_id       text,
  hidden           boolean NOT NULL DEFAULT false,
  deleted_at       timestamp,
  deleted_by       text,
  status           text NOT NULL DEFAULT 'visible',
  moderation_note  text,
  vendor_reply     text,
  vendor_replied_at timestamp,
  created_at       timestamp NOT NULL DEFAULT now(),
  CONSTRAINT reviews_rating_valid CHECK (rating BETWEEN 1 AND 5)
);
CREATE INDEX IF NOT EXISTS reviews_user_id_idx    ON reviews (user_id);
CREATE INDEX IF NOT EXISTS reviews_vendor_id_idx  ON reviews (vendor_id);
CREATE INDEX IF NOT EXISTS reviews_order_id_idx   ON reviews (order_id);
CREATE INDEX IF NOT EXISTS reviews_created_at_idx ON reviews (created_at);

-- ─── ride_ratings ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ride_ratings (
  id          text PRIMARY KEY,
  ride_id     text NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  customer_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rider_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stars       integer NOT NULL,
  comment     text,
  hidden      boolean NOT NULL DEFAULT false,
  deleted_at  timestamp,
  deleted_by  text,
  created_at  timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ride_ratings_ride_id_uidx    ON ride_ratings (ride_id);
CREATE INDEX IF NOT EXISTS ride_ratings_rider_id_idx     ON ride_ratings (rider_id);
CREATE INDEX IF NOT EXISTS ride_ratings_customer_id_idx  ON ride_ratings (customer_id);

-- ─── notifications ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id                  text PRIMARY KEY,
  user_id             text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title               text NOT NULL,
  body                text NOT NULL,
  type                text NOT NULL DEFAULT 'system',
  is_read             boolean NOT NULL DEFAULT false,
  icon                text DEFAULT 'notifications-outline',
  link                text,
  created_at          timestamp NOT NULL DEFAULT now(),
  sos_status          text DEFAULT 'pending',
  acknowledged_at     timestamp,
  acknowledged_by     text,
  acknowledged_by_name text,
  resolved_at         timestamp,
  resolved_by         text,
  resolved_by_name    text,
  resolution_notes    text
);
CREATE INDEX IF NOT EXISTS notifications_user_id_idx   ON notifications (user_id);
CREATE INDEX IF NOT EXISTS notifications_user_read_idx ON notifications (user_id, is_read);

-- ─── saved_addresses ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS saved_addresses (
  id         text PRIMARY KEY,
  user_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label      text NOT NULL,
  address    text NOT NULL,
  city       text NOT NULL DEFAULT 'Muzaffarabad',
  icon       text NOT NULL DEFAULT 'location-outline',
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS saved_addresses_user_id_idx ON saved_addresses (user_id);

-- ─── platform_settings ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS platform_settings (
  key        text PRIMARY KEY,
  value      text NOT NULL,
  label      text NOT NULL,
  category   text NOT NULL DEFAULT 'general',
  updated_at timestamp NOT NULL DEFAULT now()
);

-- ─── promo_codes ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS promo_codes (
  id              text PRIMARY KEY,
  code            text NOT NULL UNIQUE,
  description     text,
  discount_pct    decimal(5,2),
  discount_flat   decimal(10,2),
  min_order_amount decimal(10,2) NOT NULL DEFAULT '0',
  max_discount    decimal(10,2),
  usage_limit     integer,
  used_count      integer NOT NULL DEFAULT 0,
  applies_to      text NOT NULL DEFAULT 'all',
  expires_at      timestamp,
  vendor_id       text REFERENCES users(id) ON DELETE SET NULL,
  is_active       boolean NOT NULL DEFAULT true,
  created_at      timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS promo_codes_vendor_id_idx  ON promo_codes (vendor_id);
CREATE INDEX IF NOT EXISTS promo_codes_is_active_idx  ON promo_codes (is_active);
CREATE INDEX IF NOT EXISTS promo_codes_expires_at_idx ON promo_codes (expires_at);

-- ─── live_locations ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS live_locations (
  user_id       text PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  latitude      decimal(10,6) NOT NULL,
  longitude     decimal(10,6) NOT NULL,
  role          text NOT NULL,
  action        text,
  battery_level real,
  last_seen     timestamp,
  online_since  timestamp,
  updated_at    timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS live_locations_role_idx         ON live_locations (role);
CREATE INDEX IF NOT EXISTS live_locations_lat_lng_idx      ON live_locations (latitude, longitude);
CREATE INDEX IF NOT EXISTS live_locations_role_updated_idx ON live_locations (role, updated_at);

-- ─── parcel_bookings ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS parcel_bookings (
  id              text PRIMARY KEY,
  user_id         text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_name     text NOT NULL,
  sender_phone    text NOT NULL,
  pickup_address  text NOT NULL,
  receiver_name   text NOT NULL,
  receiver_phone  text NOT NULL,
  drop_address    text NOT NULL,
  parcel_type     text NOT NULL,
  weight          decimal(6,2),
  description     text,
  fare            decimal(10,2) NOT NULL,
  payment_method  text NOT NULL,
  status          text NOT NULL DEFAULT 'pending',
  estimated_time  text DEFAULT '45-60 min',
  rider_id        text REFERENCES users(id) ON DELETE SET NULL,
  created_at      timestamp NOT NULL DEFAULT now(),
  updated_at      timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS parcel_bookings_user_id_idx    ON parcel_bookings (user_id);
CREATE INDEX IF NOT EXISTS parcel_bookings_rider_id_idx   ON parcel_bookings (rider_id);
CREATE INDEX IF NOT EXISTS parcel_bookings_status_idx     ON parcel_bookings (status);
CREATE INDEX IF NOT EXISTS parcel_bookings_created_at_idx ON parcel_bookings (created_at);

-- ─── categories ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id         text PRIMARY KEY,
  name       text NOT NULL,
  icon       text NOT NULL DEFAULT 'grid-outline',
  type       text NOT NULL DEFAULT 'mart',
  parent_id  text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active  boolean NOT NULL DEFAULT true,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS categories_type_idx       ON categories (type);
CREATE INDEX IF NOT EXISTS categories_parent_id_idx  ON categories (parent_id);
CREATE INDEX IF NOT EXISTS categories_sort_order_idx ON categories (sort_order);
CREATE INDEX IF NOT EXISTS categories_is_active_idx  ON categories (is_active);

-- ─── banners ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS banners (
  id             text PRIMARY KEY,
  title          text NOT NULL,
  subtitle       text,
  image_url      text,
  link_type      text NOT NULL DEFAULT 'none',
  link_value     text,
  target_service text,
  placement      text NOT NULL DEFAULT 'home',
  color_from     text NOT NULL DEFAULT '#7C3AED',
  color_to       text NOT NULL DEFAULT '#4F46E5',
  icon           text,
  sort_order     integer NOT NULL DEFAULT 0,
  is_active      boolean NOT NULL DEFAULT true,
  start_date     timestamp,
  end_date       timestamp,
  created_at     timestamp NOT NULL DEFAULT now(),
  updated_at     timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS banners_placement_idx  ON banners (placement);
CREATE INDEX IF NOT EXISTS banners_is_active_idx  ON banners (is_active);
CREATE INDEX IF NOT EXISTS banners_sort_order_idx ON banners (sort_order);

-- ─── flash_deals ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS flash_deals (
  id            text PRIMARY KEY,
  product_id    text NOT NULL,
  title         text,
  badge         text NOT NULL DEFAULT 'FLASH',
  discount_pct  decimal(5,2),
  discount_flat decimal(10,2),
  start_time    timestamp NOT NULL,
  end_time      timestamp NOT NULL,
  deal_stock    integer,
  sold_count    integer NOT NULL DEFAULT 0,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS flash_deals_product_id_idx ON flash_deals (product_id);
CREATE INDEX IF NOT EXISTS flash_deals_is_active_idx  ON flash_deals (is_active);

-- ─── vendor_profiles ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vendor_profiles (
  user_id              text PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  store_name           text,
  store_category       text,
  store_banner         text,
  store_description    text,
  store_hours          text,
  store_announcement   text,
  store_min_order      decimal(10,2) DEFAULT '0',
  store_delivery_time  text,
  store_is_open        boolean NOT NULL DEFAULT true,
  store_address        text,
  store_lat            decimal(10,7),
  store_lng            decimal(10,7),
  business_type        text,
  business_name        text,
  ntn                  text,
  created_at           timestamp NOT NULL DEFAULT now(),
  updated_at           timestamp NOT NULL DEFAULT now()
);

-- ─── rider_profiles ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rider_profiles (
  user_id          text PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  vehicle_type     text,
  vehicle_plate    text,
  vehicle_reg_no   text,
  driving_license  text,
  vehicle_photo    text,
  documents        text,
  daily_goal       numeric(10,2),
  created_at       timestamp NOT NULL DEFAULT now(),
  updated_at       timestamp NOT NULL DEFAULT now()
);

-- ─── user_settings ───────────────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'language_mode') THEN
    CREATE TYPE language_mode AS ENUM ('en', 'ur', 'roman', 'en_roman', 'en_ur');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS user_settings (
  id               text PRIMARY KEY,
  user_id          text NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  notif_orders     boolean NOT NULL DEFAULT true,
  notif_wallet     boolean NOT NULL DEFAULT true,
  notif_deals      boolean NOT NULL DEFAULT true,
  notif_rides      boolean NOT NULL DEFAULT true,
  location_sharing boolean NOT NULL DEFAULT true,
  biometric        boolean NOT NULL DEFAULT false,
  two_factor       boolean NOT NULL DEFAULT false,
  dark_mode        boolean NOT NULL DEFAULT false,
  language         language_mode NOT NULL DEFAULT 'en_roman',
  updated_at       timestamp NOT NULL DEFAULT now()
);

-- ─── kyc_verifications ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS kyc_verifications (
  id               text PRIMARY KEY,
  user_id          text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status           text NOT NULL DEFAULT 'pending',
  full_name        text,
  cnic             text,
  date_of_birth    text,
  gender           text,
  address          text,
  city             text,
  front_id_photo   text,
  back_id_photo    text,
  selfie_photo     text,
  rejection_reason text,
  reviewed_by      text,
  reviewed_at      timestamp,
  submitted_at     timestamp NOT NULL DEFAULT now(),
  created_at       timestamp NOT NULL DEFAULT now(),
  updated_at       timestamp NOT NULL DEFAULT now()
);

-- ─── refresh_tokens ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          text PRIMARY KEY,
  user_id     text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  text NOT NULL UNIQUE,
  auth_method text,
  expires_at  timestamp NOT NULL,
  revoked_at  timestamp,
  created_at  timestamp NOT NULL DEFAULT now()
);

-- ─── user_sessions ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_sessions (
  id               text PRIMARY KEY,
  user_id          text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash       text NOT NULL,
  refresh_token_id text,
  device_name      text,
  browser          text,
  os               text,
  ip               text,
  location         text,
  last_active_at   timestamp NOT NULL DEFAULT now(),
  revoked_at       timestamp,
  created_at       timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS user_sessions_user_id_idx ON user_sessions (user_id);

-- ─── login_history ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS login_history (
  id          text PRIMARY KEY,
  user_id     text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ip          text,
  device_name text,
  browser     text,
  os          text,
  location    text,
  success     boolean NOT NULL DEFAULT true,
  method      text,
  created_at  timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS login_history_user_id_idx ON login_history (user_id);

-- ─── auth_audit_log ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS auth_audit_log (
  id         text PRIMARY KEY,
  user_id    text REFERENCES users(id) ON DELETE SET NULL,
  event      text NOT NULL,
  ip         text NOT NULL DEFAULT 'unknown',
  user_agent text,
  metadata   text,
  created_at timestamp NOT NULL DEFAULT now()
);

-- ─── pending_otps ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pending_otps (
  id         text PRIMARY KEY,
  phone      text NOT NULL UNIQUE,
  otp_hash   text NOT NULL,
  otp_expiry timestamp NOT NULL,
  attempts   integer NOT NULL DEFAULT 0,
  created_at timestamp NOT NULL DEFAULT now()
);

-- ─── push_subscriptions ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id         text PRIMARY KEY,
  user_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role       text NOT NULL DEFAULT 'customer',
  token_type text NOT NULL DEFAULT 'vapid',
  endpoint   text NOT NULL,
  p256dh     text,
  auth_key   text,
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS push_sub_user_idx ON push_subscriptions (user_id);
CREATE INDEX IF NOT EXISTS push_sub_role_idx ON push_subscriptions (role);
CREATE INDEX IF NOT EXISTS push_sub_type_idx ON push_subscriptions (token_type);

-- ─── location_logs ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS location_logs (
  id            text PRIMARY KEY,
  user_id       text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role          text NOT NULL DEFAULT 'rider',
  latitude      decimal(10,6) NOT NULL,
  longitude     decimal(10,6) NOT NULL,
  accuracy      real,
  speed         real,
  heading       real,
  battery_level real,
  is_spoofed    boolean NOT NULL DEFAULT false,
  created_at    timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS location_logs_user_ts_idx  ON location_logs (user_id, created_at);
CREATE INDEX IF NOT EXISTS location_logs_user_idx     ON location_logs (user_id);
CREATE INDEX IF NOT EXISTS location_logs_role_idx     ON location_logs (role);
CREATE INDEX IF NOT EXISTS location_logs_role_ts_idx  ON location_logs (role, created_at);
CREATE INDEX IF NOT EXISTS location_logs_lat_lng_idx  ON location_logs (latitude, longitude);

-- ─── location_history ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS location_history (
  id         serial PRIMARY KEY,
  user_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ride_id    text REFERENCES rides(id) ON DELETE SET NULL,
  order_id   text REFERENCES orders(id) ON DELETE SET NULL,
  coords     jsonb NOT NULL,
  heading    numeric(6,2),
  speed      numeric(8,2),
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS location_history_user_id_idx      ON location_history (user_id);
CREATE INDEX IF NOT EXISTS location_history_created_at_idx   ON location_history (created_at);
CREATE INDEX IF NOT EXISTS location_history_user_created_idx ON location_history (user_id, created_at);

-- ─── ride_event_logs ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ride_event_logs (
  id         text PRIMARY KEY,
  ride_id    text NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  rider_id   text REFERENCES users(id) ON DELETE CASCADE,
  admin_id   text,
  event      text NOT NULL,
  lat        decimal(10,6),
  lng        decimal(10,6),
  notes      text,
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ride_event_logs_ride_id_idx  ON ride_event_logs (ride_id);
CREATE INDEX IF NOT EXISTS ride_event_logs_rider_id_idx ON ride_event_logs (rider_id);

-- ─── ride_notified_riders ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ride_notified_riders (
  id         text PRIMARY KEY,
  ride_id    text NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  rider_id   text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ride_notified_riders_ride_rider_uidx ON ride_notified_riders (ride_id, rider_id);
CREATE INDEX IF NOT EXISTS ride_notified_riders_ride_id_idx ON ride_notified_riders (ride_id);

-- ─── rider_penalties ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rider_penalties (
  id         text PRIMARY KEY,
  rider_id   text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       text NOT NULL,
  amount     decimal(10,2) NOT NULL DEFAULT '0',
  reason     text,
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS rider_penalties_rider_id_idx   ON rider_penalties (rider_id);
CREATE INDEX IF NOT EXISTS rider_penalties_type_idx       ON rider_penalties (type);
CREATE INDEX IF NOT EXISTS rider_penalties_created_at_idx ON rider_penalties (created_at);

-- ─── ride_service_types ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ride_service_types (
  id              text PRIMARY KEY,
  key             text NOT NULL UNIQUE,
  name            text NOT NULL,
  name_urdu       text,
  icon            text NOT NULL DEFAULT '🚗',
  description     text,
  color           text NOT NULL DEFAULT '#059669',
  is_enabled      boolean NOT NULL DEFAULT true,
  is_custom       boolean NOT NULL DEFAULT false,
  base_fare       decimal(10,2) NOT NULL DEFAULT '15',
  per_km          decimal(10,2) NOT NULL DEFAULT '8',
  min_fare        decimal(10,2) NOT NULL DEFAULT '50',
  max_passengers  integer NOT NULL DEFAULT 1,
  allow_bargaining boolean NOT NULL DEFAULT true,
  sort_order      integer NOT NULL DEFAULT 0,
  created_at      timestamp NOT NULL DEFAULT now(),
  updated_at      timestamp NOT NULL DEFAULT now()
);

-- ─── popular_locations ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS popular_locations (
  id         text PRIMARY KEY,
  name       text NOT NULL,
  name_urdu  text,
  lat        decimal(10,7) NOT NULL,
  lng        decimal(10,7) NOT NULL,
  category   text NOT NULL DEFAULT 'general',
  icon       text NOT NULL DEFAULT '📍',
  is_active  boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);

-- ─── service_zones ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS service_zones (
  id                serial PRIMARY KEY,
  name              text NOT NULL,
  city              text NOT NULL,
  lat               numeric(10,6) NOT NULL,
  lng               numeric(10,6) NOT NULL,
  radius_km         numeric(8,2) NOT NULL DEFAULT '30',
  is_active         boolean NOT NULL DEFAULT true,
  applies_to_rides  boolean NOT NULL DEFAULT true,
  applies_to_orders boolean NOT NULL DEFAULT true,
  applies_to_parcel boolean NOT NULL DEFAULT true,
  notes             text,
  created_at        timestamp NOT NULL DEFAULT now(),
  updated_at        timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS service_zones_is_active_idx ON service_zones (is_active);

-- ─── wishlist ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wishlist (
  id         text PRIMARY KEY,
  user_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id text NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS wishlist_user_product_uidx ON wishlist (user_id, product_id);
CREATE INDEX IF NOT EXISTS wishlist_user_id_idx ON wishlist (user_id);

-- ─── user_interactions ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_interactions (
  id               text PRIMARY KEY,
  user_id          text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id       text NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  interaction_type text NOT NULL DEFAULT 'view',
  weight           integer NOT NULL DEFAULT 1,
  created_at       timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS user_interactions_user_id_idx    ON user_interactions (user_id);
CREATE INDEX IF NOT EXISTS user_interactions_product_id_idx ON user_interactions (product_id);
CREATE INDEX IF NOT EXISTS user_interactions_type_idx       ON user_interactions (interaction_type);
CREATE INDEX IF NOT EXISTS user_interactions_created_at_idx ON user_interactions (created_at);

-- ─── stock_subscriptions ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stock_subscriptions (
  id         text PRIMARY KEY,
  user_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id text NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at timestamp NOT NULL DEFAULT now(),
  CONSTRAINT stock_subscriptions_user_product_uniq UNIQUE (user_id, product_id)
);
CREATE INDEX IF NOT EXISTS stock_subscriptions_user_id_idx    ON stock_subscriptions (user_id);
CREATE INDEX IF NOT EXISTS stock_subscriptions_product_id_idx ON stock_subscriptions (product_id);

-- ─── idempotency_keys ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS idempotency_keys (
  id               text PRIMARY KEY,
  user_id          text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  idempotency_key  text NOT NULL,
  response_data    text NOT NULL,
  created_at       timestamp NOT NULL DEFAULT now(),
  CONSTRAINT idempotency_keys_user_key_uniq UNIQUE (user_id, idempotency_key)
);

-- ─── error_reports ───────────────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'error_source_app') THEN
    CREATE TYPE error_source_app AS ENUM ('customer', 'rider', 'vendor', 'admin', 'api');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'error_type') THEN
    CREATE TYPE error_type AS ENUM ('frontend_crash', 'api_error', 'db_error', 'route_error', 'ui_error', 'unhandled_exception');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'error_severity') THEN
    CREATE TYPE error_severity AS ENUM ('critical', 'medium', 'minor');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'error_status') THEN
    CREATE TYPE error_status AS ENUM ('new', 'acknowledged', 'in_progress', 'resolved');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'resolution_method') THEN
    CREATE TYPE resolution_method AS ENUM ('manual', 'auto_resolved', 'task_created');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS error_reports (
  id               text PRIMARY KEY,
  timestamp        timestamp NOT NULL DEFAULT now(),
  source_app       error_source_app NOT NULL,
  error_type       error_type NOT NULL,
  severity         error_severity NOT NULL,
  status           error_status NOT NULL DEFAULT 'new',
  function_name    text,
  error_message    text,
  stack_trace      text,
  component_name   text,
  route            text,
  user_id          text,
  session_id       text,
  app_version      text,
  platform         text,
  device_info      text,
  metadata         jsonb,
  resolution_notes text,
  resolution_method resolution_method,
  resolved_at      timestamp,
  resolved_by      text,
  error_hash       text,
  created_at       timestamp NOT NULL DEFAULT now(),
  updated_at       timestamp NOT NULL DEFAULT now()
);

-- ─── customer_error_reports ──────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'customer_report_status') THEN
    CREATE TYPE customer_report_status AS ENUM ('new', 'reviewed', 'closed');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS customer_error_reports (
  id              text PRIMARY KEY,
  timestamp       timestamp NOT NULL DEFAULT now(),
  customer_name   text NOT NULL,
  customer_email  text,
  customer_phone  text,
  user_id         text,
  app_version     text,
  device_info     text,
  platform        text,
  screen          text,
  description     text NOT NULL,
  repro_steps     text,
  status          customer_report_status NOT NULL DEFAULT 'new',
  reviewed_at     timestamp,
  reviewed_by     text,
  created_at      timestamp NOT NULL DEFAULT now()
);

-- ─── error_resolution_backups ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS error_resolution_backups (
  id                text PRIMARY KEY,
  error_report_id   text NOT NULL,
  previous_status   text NOT NULL,
  previous_data     jsonb NOT NULL,
  resolution_method text NOT NULL,
  created_at        timestamp NOT NULL DEFAULT now(),
  expires_at        timestamp NOT NULL
);

-- ─── auto_resolve_log ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS auto_resolve_log (
  id              text PRIMARY KEY,
  error_report_id text NOT NULL,
  reason          text NOT NULL,
  rule_matched    text NOT NULL,
  created_at      timestamp NOT NULL DEFAULT now()
);

-- ─── file_scan_results ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS file_scan_results (
  id              text PRIMARY KEY,
  scanned_at      timestamp NOT NULL DEFAULT now(),
  duration_ms     integer NOT NULL,
  total_findings  integer NOT NULL,
  findings        jsonb NOT NULL,
  triggered_by    text NOT NULL DEFAULT 'manual'
);

-- ─── system_snapshots ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS system_snapshots (
  id          text PRIMARY KEY,
  label       text NOT NULL,
  action_id   text NOT NULL,
  tables_json text NOT NULL,
  created_at  timestamp NOT NULL DEFAULT now(),
  expires_at  timestamp NOT NULL
);

-- ─── demo_backups ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS demo_backups (
  id          text PRIMARY KEY,
  label       text NOT NULL,
  tables_json text NOT NULL,
  rows_total  integer NOT NULL DEFAULT 0,
  size_kb     integer NOT NULL DEFAULT 0,
  created_at  timestamp NOT NULL DEFAULT now()
);

-- ─── map_api_usage_log ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS map_api_usage_log (
  id            serial PRIMARY KEY,
  provider      text NOT NULL,
  endpoint_type text NOT NULL,
  count         integer NOT NULL DEFAULT 0,
  date          date NOT NULL,
  created_at    timestamp NOT NULL DEFAULT now(),
  updated_at    timestamp NOT NULL DEFAULT now(),
  CONSTRAINT map_api_usage_log_unique UNIQUE (provider, endpoint_type, date)
);

-- ─── search_logs ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS search_logs (
  id           integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  query        text NOT NULL,
  result_count integer NOT NULL DEFAULT 0,
  user_id      text,
  created_at   timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS search_logs_result_count_created_at_idx ON search_logs (result_count, created_at);
CREATE INDEX IF NOT EXISTS search_logs_query_idx      ON search_logs (query);
CREATE INDEX IF NOT EXISTS search_logs_created_at_idx ON search_logs (created_at);

-- ─── integration_test_history ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS integration_test_history (
  id           text PRIMARY KEY,
  type         text NOT NULL,
  ok           boolean NOT NULL,
  latency_ms   integer NOT NULL DEFAULT 0,
  message      text NOT NULL DEFAULT '',
  error_detail text,
  admin_id     text,
  created_at   timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS integration_test_history_type_idx       ON integration_test_history (type);
CREATE INDEX IF NOT EXISTS integration_test_history_created_at_idx ON integration_test_history (created_at);

-- ─── sms_gateways ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sms_gateways (
  id           text PRIMARY KEY,
  name         text NOT NULL,
  provider     text NOT NULL,
  priority     integer NOT NULL DEFAULT 10,
  is_active    boolean NOT NULL DEFAULT true,
  account_sid  text,
  auth_token   text,
  from_number  text,
  msg91_key    text,
  sender_id    text,
  api_key      text,
  api_url      text,
  created_at   timestamp NOT NULL DEFAULT now(),
  updated_at   timestamp NOT NULL DEFAULT now()
);

-- ─── whitelist_users ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS whitelist_users (
  id          text PRIMARY KEY,
  identifier  text NOT NULL UNIQUE,
  label       text,
  bypass_code text NOT NULL DEFAULT '000000',
  is_active   boolean NOT NULL DEFAULT true,
  expires_at  timestamp,
  created_at  timestamp NOT NULL DEFAULT now()
);

-- ─── otp_bypass_audit ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS otp_bypass_audit (
  id         text PRIMARY KEY,
  event_type text NOT NULL,
  admin_id   text,
  target_id  text,
  details    jsonb,
  created_at timestamp NOT NULL DEFAULT now()
);

-- ─── consent_log ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS consent_log (
  id               text PRIMARY KEY,
  user_id          text NOT NULL,
  consent_type     text NOT NULL,
  consent_version  text NOT NULL,
  ip_address       text,
  user_agent       text,
  source           text,
  created_at       timestamp NOT NULL DEFAULT now()
);

-- ─── terms_versions ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS terms_versions (
  policy        text NOT NULL,
  version       text NOT NULL,
  effective_at  timestamp NOT NULL DEFAULT now(),
  body_markdown text,
  changelog     text,
  created_at    timestamp NOT NULL DEFAULT now(),
  PRIMARY KEY (policy, version)
);

-- ─── support_messages ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS support_messages (
  id              text PRIMARY KEY,
  user_id         text NOT NULL,
  message         text NOT NULL,
  is_from_support boolean NOT NULL DEFAULT false,
  is_read_by_admin boolean NOT NULL DEFAULT false,
  is_resolved     boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- ─── platform_settings seed ──────────────────────────────────────────────────
INSERT INTO platform_settings (key, value, label, category) VALUES
  ('security_otp_disabled', 'false', 'Disable OTP (allow all logins)', 'security')
ON CONFLICT (key) DO NOTHING;

-- ─── faqs ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS faqs (
  id         text PRIMARY KEY,
  category   text NOT NULL DEFAULT 'General',
  question   text NOT NULL,
  answer     text NOT NULL,
  is_active  boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ─── release_notes ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS release_notes (
  id           text PRIMARY KEY,
  version      text NOT NULL,
  release_date text NOT NULL,
  notes        text NOT NULL,
  sort_order   integer NOT NULL DEFAULT 0,
  created_at   timestamp NOT NULL DEFAULT now(),
  updated_at   timestamp NOT NULL DEFAULT now()
);

-- ─── deep_links ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS deep_links (
  id            text PRIMARY KEY,
  short_code    text NOT NULL UNIQUE,
  target_screen text NOT NULL,
  params        jsonb NOT NULL DEFAULT '{}',
  label         text NOT NULL DEFAULT '',
  click_count   integer NOT NULL DEFAULT 0,
  created_at    timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS deep_links_short_code_idx ON deep_links (short_code);
CREATE INDEX IF NOT EXISTS deep_links_target_idx     ON deep_links (target_screen);

-- ─── qr_codes ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qr_codes (
  id         text PRIMARY KEY,
  code       text NOT NULL UNIQUE,
  type       text NOT NULL DEFAULT 'payment',
  label      text NOT NULL,
  is_active  boolean NOT NULL DEFAULT true,
  created_by text REFERENCES users(id),
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS qr_codes_type_idx      ON qr_codes (type);
CREATE INDEX IF NOT EXISTS qr_codes_is_active_idx ON qr_codes (is_active);
CREATE INDEX IF NOT EXISTS qr_codes_code_idx      ON qr_codes (code);

-- ─── weather_config ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS weather_config (
  id             text PRIMARY KEY DEFAULT 'default',
  widget_enabled boolean NOT NULL DEFAULT true,
  cities         text NOT NULL DEFAULT 'Muzaffarabad,Rawalakot,Mirpur,Bagh,Kotli,Neelum',
  updated_at     timestamp NOT NULL DEFAULT now()
);
INSERT INTO weather_config (id) VALUES ('default') ON CONFLICT DO NOTHING;

-- ─── webhook_registrations ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS webhook_registrations (
  id          text PRIMARY KEY,
  url         text NOT NULL,
  events      jsonb NOT NULL DEFAULT '[]',
  secret      text,
  is_active   boolean NOT NULL DEFAULT true,
  description text NOT NULL DEFAULT '',
  created_at  timestamp NOT NULL DEFAULT now(),
  updated_at  timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS webhook_registrations_active_idx ON webhook_registrations (is_active);

CREATE TABLE IF NOT EXISTS webhook_logs (
  id            text PRIMARY KEY,
  webhook_id    text NOT NULL REFERENCES webhook_registrations(id),
  event         text NOT NULL,
  url           text NOT NULL,
  status        integer,
  request_body  jsonb,
  response_body text,
  success       boolean NOT NULL DEFAULT false,
  error         text,
  duration_ms   integer,
  created_at    timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS webhook_logs_webhook_idx ON webhook_logs (webhook_id);
CREATE INDEX IF NOT EXISTS webhook_logs_event_idx   ON webhook_logs (event);
CREATE INDEX IF NOT EXISTS webhook_logs_created_idx ON webhook_logs (created_at);

-- ─── vendor_schedules ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vendor_schedules (
  id          text PRIMARY KEY,
  vendor_id   text NOT NULL,
  day_of_week integer NOT NULL,
  open_time   text NOT NULL DEFAULT '09:00',
  close_time  text NOT NULL DEFAULT '21:00',
  is_enabled  boolean NOT NULL DEFAULT true,
  created_at  timestamp NOT NULL DEFAULT now(),
  updated_at  timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS vendor_schedules_vendor_day_idx ON vendor_schedules (vendor_id, day_of_week);

-- ─── van_routes ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS van_routes (
  id                  text PRIMARY KEY,
  name                text NOT NULL,
  name_urdu           text,
  from_address        text NOT NULL,
  from_address_urdu   text,
  from_lat            decimal(10,7),
  from_lng            decimal(10,7),
  to_address          text NOT NULL,
  to_address_urdu     text,
  to_lat              decimal(10,7),
  to_lng              decimal(10,7),
  distance_km         decimal(6,2),
  duration_min        integer,
  fare_per_seat       decimal(10,2) NOT NULL,
  fare_window         decimal(10,2),
  fare_aisle          decimal(10,2),
  fare_economy        decimal(10,2),
  notes               text,
  is_active           boolean NOT NULL DEFAULT true,
  sort_order          integer NOT NULL DEFAULT 0,
  created_at          timestamp NOT NULL DEFAULT now(),
  updated_at          timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS van_routes_is_active_idx ON van_routes (is_active);

-- ─── van_vehicles ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS van_vehicles (
  id           text PRIMARY KEY,
  driver_id    text REFERENCES users(id) ON DELETE SET NULL,
  plate_number text NOT NULL,
  model        text NOT NULL DEFAULT 'Suzuki Carry',
  total_seats  integer NOT NULL DEFAULT 12,
  seat_layout  jsonb DEFAULT null,
  is_active    boolean NOT NULL DEFAULT true,
  created_at   timestamp NOT NULL DEFAULT now(),
  updated_at   timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS van_vehicles_driver_id_idx ON van_vehicles (driver_id);

-- ─── van_drivers ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS van_drivers (
  id              text PRIMARY KEY,
  user_id         text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  van_code        text NOT NULL UNIQUE,
  approval_status text NOT NULL DEFAULT 'pending',
  is_active       boolean NOT NULL DEFAULT true,
  notes           text,
  created_at      timestamp NOT NULL DEFAULT now(),
  updated_at      timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS van_drivers_user_id_idx  ON van_drivers (user_id);
CREATE INDEX IF NOT EXISTS van_drivers_van_code_idx ON van_drivers (van_code);

-- ─── van_schedules ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS van_schedules (
  id              text PRIMARY KEY,
  route_id        text NOT NULL REFERENCES van_routes(id) ON DELETE CASCADE,
  vehicle_id      text REFERENCES van_vehicles(id) ON DELETE SET NULL,
  van_driver_id   text,
  departure_time  text NOT NULL,
  arrival_time    text,
  days_of_week    jsonb NOT NULL DEFAULT '[1,2,3,4,5,6]',
  trip_status     text NOT NULL DEFAULT 'idle',
  is_active       boolean NOT NULL DEFAULT true,
  created_at      timestamp NOT NULL DEFAULT now(),
  updated_at      timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS van_schedules_route_id_idx   ON van_schedules (route_id);
CREATE INDEX IF NOT EXISTS van_schedules_vehicle_id_idx ON van_schedules (vehicle_id);

-- ─── van_bookings ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS van_bookings (
  id              text PRIMARY KEY,
  user_id         text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  schedule_id     text NOT NULL REFERENCES van_schedules(id) ON DELETE CASCADE,
  seat_numbers    jsonb NOT NULL DEFAULT '[]',
  seat_tiers      jsonb,
  tier_label      text,
  price_paid      decimal(10,2),
  tier_breakdown  jsonb,
  total_amount    decimal(10,2) NOT NULL,
  payment_method  text NOT NULL DEFAULT 'cash',
  status          text NOT NULL DEFAULT 'pending',
  travel_date     date NOT NULL,
  notes           text,
  created_at      timestamp NOT NULL DEFAULT now(),
  updated_at      timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS van_bookings_user_id_idx     ON van_bookings (user_id);
CREATE INDEX IF NOT EXISTS van_bookings_schedule_id_idx ON van_bookings (schedule_id);
CREATE INDEX IF NOT EXISTS van_bookings_status_idx      ON van_bookings (status);

-- ─── school_routes ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS school_routes (
  id               text PRIMARY KEY,
  route_name       text NOT NULL,
  school_name      text NOT NULL,
  school_name_urdu text,
  from_area        text NOT NULL,
  from_area_urdu   text,
  to_address       text NOT NULL,
  from_lat         decimal(10,6),
  from_lng         decimal(10,6),
  to_lat           decimal(10,6),
  to_lng           decimal(10,6),
  monthly_price    decimal(10,2) NOT NULL,
  morning_time     text DEFAULT '7:30 AM',
  afternoon_time   text,
  capacity         integer NOT NULL DEFAULT 30,
  enrolled_count   integer NOT NULL DEFAULT 0,
  vehicle_type     text NOT NULL DEFAULT 'school_shift',
  notes            text,
  is_active        boolean NOT NULL DEFAULT true,
  sort_order       integer NOT NULL DEFAULT 0,
  created_at       timestamp NOT NULL DEFAULT now(),
  updated_at       timestamp NOT NULL DEFAULT now()
);

-- ─── school_subscriptions ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS school_subscriptions (
  id                text PRIMARY KEY,
  user_id           text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  route_id          text NOT NULL REFERENCES school_routes(id) ON DELETE CASCADE,
  student_name      text NOT NULL,
  student_class     text NOT NULL,
  monthly_amount    decimal(10,2) NOT NULL,
  status            text NOT NULL DEFAULT 'active',
  payment_method    text NOT NULL DEFAULT 'cash',
  start_date        timestamp NOT NULL DEFAULT now(),
  next_billing_date timestamp,
  notes             text,
  created_at        timestamp NOT NULL DEFAULT now(),
  updated_at        timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS school_subs_user_id_idx  ON school_subscriptions (user_id);
CREATE INDEX IF NOT EXISTS school_subs_route_id_idx ON school_subscriptions (route_id);
CREATE INDEX IF NOT EXISTS school_subs_status_idx   ON school_subscriptions (status);

-- ─── RBAC ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rbac_permissions (
  id          text PRIMARY KEY,
  label       text NOT NULL,
  category    text NOT NULL,
  description text,
  created_at  timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rbac_roles (
  id          text PRIMARY KEY,
  slug        text NOT NULL UNIQUE,
  name        text NOT NULL,
  description text,
  is_built_in boolean NOT NULL DEFAULT false,
  created_at  timestamp NOT NULL DEFAULT now(),
  updated_at  timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rbac_role_permissions (
  role_id       text NOT NULL,
  permission_id text NOT NULL,
  created_at    timestamp NOT NULL DEFAULT now(),
  PRIMARY KEY (role_id, permission_id)
);
CREATE INDEX IF NOT EXISTS rbac_role_permissions_role_idx ON rbac_role_permissions (role_id);

CREATE TABLE IF NOT EXISTS rbac_admin_role_assignments (
  admin_id   text NOT NULL,
  role_id    text NOT NULL,
  granted_by text,
  granted_at timestamp NOT NULL DEFAULT now(),
  PRIMARY KEY (admin_id, role_id)
);
CREATE INDEX IF NOT EXISTS rbac_admin_role_assignments_admin_idx ON rbac_admin_role_assignments (admin_id);

-- ─── admin_role_presets ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_role_presets (
  id               text PRIMARY KEY,
  name             text NOT NULL,
  slug             text NOT NULL UNIQUE,
  description      text NOT NULL DEFAULT '',
  permissions_json text NOT NULL DEFAULT '[]',
  role             text NOT NULL DEFAULT 'manager',
  is_built_in      boolean NOT NULL DEFAULT false,
  created_at       timestamp NOT NULL DEFAULT now()
);

-- ─── admin_action_audit_log ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_action_audit_log (
  id                  text PRIMARY KEY,
  admin_id            text REFERENCES admin_accounts(id) ON DELETE SET NULL,
  admin_name          text,
  ip                  text NOT NULL DEFAULT 'unknown',
  action              text NOT NULL,
  result              text NOT NULL DEFAULT 'success',
  details             text,
  affected_user_id    text REFERENCES users(id) ON DELETE SET NULL,
  affected_user_name  text,
  affected_user_role  text,
  created_at          timestamp NOT NULL DEFAULT now()
);

-- ─── admin_password_reset_tokens ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_password_reset_tokens (
  id               text PRIMARY KEY,
  admin_id         text NOT NULL REFERENCES admin_accounts(id) ON DELETE CASCADE,
  token_hash       text NOT NULL UNIQUE,
  requested_by     text NOT NULL DEFAULT 'self',
  requester_admin_id text,
  expires_at       timestamp NOT NULL,
  used_at          timestamp,
  created_at       timestamp NOT NULL DEFAULT now()
);

-- ─── admin_password_hash_snapshots ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_password_hash_snapshots (
  id         text PRIMARY KEY,
  admin_id   text NOT NULL REFERENCES admin_accounts(id) ON DELETE CASCADE,
  hash       text NOT NULL,
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS admin_pw_hash_snap_admin_idx ON admin_password_hash_snapshots (admin_id);

-- ─── ab_experiments ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ab_experiments (
  id          text PRIMARY KEY,
  name        text NOT NULL,
  description text NOT NULL DEFAULT '',
  status      text NOT NULL DEFAULT 'draft',
  variants    jsonb NOT NULL DEFAULT '[]',
  traffic_pct integer NOT NULL DEFAULT 100,
  created_at  timestamp NOT NULL DEFAULT now(),
  updated_at  timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ab_experiments_status_idx ON ab_experiments (status);

CREATE TABLE IF NOT EXISTS ab_assignments (
  id            text PRIMARY KEY,
  experiment_id text NOT NULL REFERENCES ab_experiments(id),
  user_id       text NOT NULL,
  variant       text NOT NULL,
  converted     boolean NOT NULL DEFAULT false,
  assigned_at   timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ab_assignments_experiment_idx ON ab_assignments (experiment_id);
CREATE INDEX IF NOT EXISTS ab_assignments_user_idx       ON ab_assignments (user_id);
CREATE INDEX IF NOT EXISTS ab_assignments_variant_idx    ON ab_assignments (variant);
CREATE UNIQUE INDEX IF NOT EXISTS ab_assignments_exp_user_unique ON ab_assignments (experiment_id, user_id);

-- ─── account_conditions ──────────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'condition_type') THEN
    CREATE TYPE condition_type AS ENUM (
      'warning_l1', 'warning_l2', 'warning_l3',
      'restriction_service_block', 'restriction_wallet_freeze', 'restriction_promo_block',
      'restriction_order_cap', 'restriction_review_block', 'restriction_cash_only',
      'restriction_new_order_block', 'restriction_rate_limit', 'restriction_pending_review_gate',
      'restriction_device_restriction',
      'suspension_temporary', 'suspension_extended', 'suspension_pending_review',
      'ban_soft', 'ban_hard', 'ban_fraud'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'condition_severity') THEN
    CREATE TYPE condition_severity AS ENUM (
      'warning', 'restriction_normal', 'restriction_strict', 'suspension', 'ban'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'condition_mode') THEN
    CREATE TYPE condition_mode AS ENUM ('default', 'ai_recommended', 'custom');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS account_conditions (
  id             text PRIMARY KEY,
  user_id        text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_role      text NOT NULL,
  condition_type condition_type NOT NULL,
  severity       condition_severity NOT NULL,
  category       text NOT NULL,
  reason         text NOT NULL,
  notes          text,
  applied_by     text,
  applied_at     timestamp NOT NULL DEFAULT now(),
  expires_at     timestamp,
  lifted_at      timestamp,
  lifted_by      text,
  lift_reason    text,
  is_active      boolean NOT NULL DEFAULT true,
  metadata       jsonb,
  created_at     timestamp NOT NULL DEFAULT now(),
  updated_at     timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS account_conditions_user_id_idx   ON account_conditions (user_id);
CREATE INDEX IF NOT EXISTS account_conditions_type_idx      ON account_conditions (condition_type);
CREATE INDEX IF NOT EXISTS account_conditions_severity_idx  ON account_conditions (severity);
CREATE INDEX IF NOT EXISTS account_conditions_is_active_idx ON account_conditions (is_active);

-- ─── condition_rules ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS condition_rules (
  id             text PRIMARY KEY,
  trigger_event  text NOT NULL,
  conditions     jsonb NOT NULL DEFAULT '{}',
  action         condition_type NOT NULL,
  severity       condition_severity NOT NULL,
  duration_hours integer,
  message        text,
  is_active      boolean NOT NULL DEFAULT true,
  created_at     timestamp NOT NULL DEFAULT now(),
  updated_at     timestamp NOT NULL DEFAULT now()
);

-- ─── condition_settings ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS condition_settings (
  key        text PRIMARY KEY,
  value      text NOT NULL,
  label      text NOT NULL,
  updated_at timestamp NOT NULL DEFAULT now()
);

-- ─── delivery_whitelist ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS delivery_whitelist (
  id             text PRIMARY KEY,
  type           text NOT NULL,
  target_id      text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_type   text NOT NULL DEFAULT 'all',
  status         text NOT NULL DEFAULT 'active',
  valid_until    timestamp,
  delivery_label text,
  notes          text,
  created_by     text,
  created_at     timestamp NOT NULL DEFAULT now(),
  updated_at     timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS delivery_whitelist_type_target_service_idx ON delivery_whitelist (type, target_id, service_type);
CREATE INDEX IF NOT EXISTS delivery_whitelist_type_status_idx         ON delivery_whitelist (type, status);

CREATE TABLE IF NOT EXISTS delivery_access_requests (
  id           text PRIMARY KEY,
  vendor_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_type text NOT NULL DEFAULT 'all',
  status       text NOT NULL DEFAULT 'pending',
  requested_at timestamp NOT NULL DEFAULT now(),
  resolved_at  timestamp,
  resolved_by  text,
  notes        text
);
CREATE INDEX IF NOT EXISTS delivery_access_requests_vendor_idx ON delivery_access_requests (vendor_id);
CREATE INDEX IF NOT EXISTS delivery_access_requests_status_idx ON delivery_access_requests (status);

CREATE TABLE IF NOT EXISTS system_audit_log (
  id          text PRIMARY KEY,
  admin_id    text,
  admin_name  text,
  action      text NOT NULL,
  target_type text,
  target_id   text,
  old_value   text,
  new_value   text,
  created_at  timestamp NOT NULL DEFAULT now()
);

-- ─── comm_conversations ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comm_conversations (
  id              text PRIMARY KEY,
  participant1_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  participant2_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type            text NOT NULL DEFAULT 'direct',
  status          text NOT NULL DEFAULT 'active',
  context_type    text,
  context_id      text,
  last_message_at timestamp,
  created_at      timestamp NOT NULL DEFAULT now(),
  updated_at      timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS conv_p1_idx       ON comm_conversations (participant1_id);
CREATE INDEX IF NOT EXISTS conv_p2_idx       ON comm_conversations (participant2_id);
CREATE INDEX IF NOT EXISTS conv_status_idx   ON comm_conversations (status);
CREATE INDEX IF NOT EXISTS conv_last_msg_idx ON comm_conversations (last_message_at);

-- ─── chat_messages ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_messages (
  id                    text PRIMARY KEY,
  conversation_id       text NOT NULL REFERENCES comm_conversations(id) ON DELETE CASCADE,
  sender_id             text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content               text,
  original_content      text,
  translated_content    text,
  message_type          text NOT NULL DEFAULT 'text',
  voice_note_url        text,
  voice_note_transcript text,
  voice_note_duration   integer,
  voice_note_waveform   text,
  image_url             text,
  file_url              text,
  file_name             text,
  is_read               boolean NOT NULL DEFAULT false,
  is_deleted            boolean NOT NULL DEFAULT false,
  deleted_at            timestamp,
  reply_to_id           text,
  created_at            timestamp NOT NULL DEFAULT now(),
  updated_at            timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS chat_messages_conv_idx       ON chat_messages (conversation_id);
CREATE INDEX IF NOT EXISTS chat_messages_sender_idx     ON chat_messages (sender_id);
CREATE INDEX IF NOT EXISTS chat_messages_created_at_idx ON chat_messages (created_at);

-- ─── communication_requests ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS communication_requests (
  id          text PRIMARY KEY,
  sender_id   text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status      text NOT NULL DEFAULT 'pending',
  expires_at  timestamp,
  created_at  timestamp NOT NULL DEFAULT now(),
  updated_at  timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS comm_req_sender_idx   ON communication_requests (sender_id);
CREATE INDEX IF NOT EXISTS comm_req_receiver_idx ON communication_requests (receiver_id);
CREATE INDEX IF NOT EXISTS comm_req_status_idx   ON communication_requests (status);

-- ─── chat_reports ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_reports (
  id               text PRIMARY KEY,
  reporter_id      text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reported_user_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message_id       text REFERENCES chat_messages(id) ON DELETE SET NULL,
  reason           text NOT NULL,
  status           text NOT NULL DEFAULT 'pending',
  resolved_by      text,
  resolved_at      timestamp,
  created_at       timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS chat_reports_reporter_idx  ON chat_reports (reporter_id);
CREATE INDEX IF NOT EXISTS chat_reports_reported_idx  ON chat_reports (reported_user_id);
CREATE INDEX IF NOT EXISTS chat_reports_status_idx    ON chat_reports (status);

-- ─── campaigns ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS campaigns (
  id           text PRIMARY KEY,
  name         text NOT NULL,
  description  text,
  theme        text NOT NULL DEFAULT 'general',
  color_from   text NOT NULL DEFAULT '#7C3AED',
  color_to     text NOT NULL DEFAULT '#4F46E5',
  banner_image text,
  priority     integer NOT NULL DEFAULT 0,
  budget_cap   numeric(12,2),
  budget_spent numeric(12,2) NOT NULL DEFAULT '0',
  start_date   timestamp NOT NULL,
  end_date     timestamp NOT NULL,
  status       text NOT NULL DEFAULT 'draft',
  created_by   text,
  approved_by  text,
  created_at   timestamp NOT NULL DEFAULT now(),
  updated_at   timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS campaigns_status_idx     ON campaigns (status);
CREATE INDEX IF NOT EXISTS campaigns_start_date_idx ON campaigns (start_date);
CREATE INDEX IF NOT EXISTS campaigns_end_date_idx   ON campaigns (end_date);
CREATE INDEX IF NOT EXISTS campaigns_priority_idx   ON campaigns (priority);

-- ─── offers ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS offers (
  id               text PRIMARY KEY,
  campaign_id      text REFERENCES campaigns(id) ON DELETE SET NULL,
  name             text NOT NULL,
  description      text,
  type             text NOT NULL,
  code             text UNIQUE,
  discount_pct     decimal(5,2),
  discount_flat    decimal(10,2),
  min_order_amount decimal(10,2) NOT NULL DEFAULT '0',
  max_discount     decimal(10,2),
  buy_qty          integer,
  get_qty          integer,
  cashback_pct     decimal(5,2),
  cashback_max     decimal(10,2),
  free_delivery    boolean NOT NULL DEFAULT false,
  targeting_rules  jsonb NOT NULL DEFAULT '{}',
  stackable        boolean NOT NULL DEFAULT false,
  usage_limit      integer,
  usage_per_user   integer NOT NULL DEFAULT 1,
  used_count       integer NOT NULL DEFAULT 0,
  applies_to       text NOT NULL DEFAULT 'all',
  vendor_id        text,
  status           text NOT NULL DEFAULT 'draft',
  start_date       timestamp NOT NULL,
  end_date         timestamp NOT NULL,
  created_by       text,
  approved_by      text,
  sort_order       integer NOT NULL DEFAULT 0,
  created_at       timestamp NOT NULL DEFAULT now(),
  updated_at       timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS offers_campaign_id_idx ON offers (campaign_id);
CREATE INDEX IF NOT EXISTS offers_status_idx      ON offers (status);
CREATE INDEX IF NOT EXISTS offers_type_idx        ON offers (type);

-- ─── offer_templates ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS offer_templates (
  id               text PRIMARY KEY,
  name             text NOT NULL,
  description      text,
  type             text NOT NULL,
  code             text,
  discount_pct     decimal(5,2),
  discount_flat    decimal(10,2),
  min_order_amount decimal(10,2) NOT NULL DEFAULT '0',
  max_discount     decimal(10,2),
  free_delivery    boolean NOT NULL DEFAULT false,
  targeting_rules  jsonb NOT NULL DEFAULT '{}',
  stackable        boolean NOT NULL DEFAULT false,
  usage_limit      integer,
  usage_per_user   integer NOT NULL DEFAULT 1,
  applies_to       text NOT NULL DEFAULT 'all',
  sort_order       integer NOT NULL DEFAULT 0,
  created_by       text,
  created_at       timestamp NOT NULL DEFAULT now(),
  updated_at       timestamp NOT NULL DEFAULT now()
);

-- ─── offer_redemptions ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS offer_redemptions (
  id         text PRIMARY KEY,
  offer_id   text NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
  user_id    text NOT NULL,
  order_id   text,
  discount   decimal(10,2) NOT NULL,
  created_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS offer_redemptions_offer_id_idx   ON offer_redemptions (offer_id);
CREATE INDEX IF NOT EXISTS offer_redemptions_user_id_idx    ON offer_redemptions (user_id);
CREATE INDEX IF NOT EXISTS offer_redemptions_order_id_idx   ON offer_redemptions (order_id);
CREATE INDEX IF NOT EXISTS offer_redemptions_created_at_idx ON offer_redemptions (created_at);

-- ─── campaign_participations ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS campaign_participations (
  id          text PRIMARY KEY,
  campaign_id text NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  vendor_id   text NOT NULL,
  status      text NOT NULL DEFAULT 'pending',
  notes       text,
  created_at  timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS campaign_participations_campaign_id_idx ON campaign_participations (campaign_id);
CREATE INDEX IF NOT EXISTS campaign_participations_vendor_id_idx   ON campaign_participations (vendor_id);

-- ─── popup_templates ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS popup_templates (
  id                text PRIMARY KEY,
  name              text NOT NULL,
  description       text,
  category          text DEFAULT 'general',
  popup_type        text NOT NULL DEFAULT 'modal',
  default_title     text,
  default_body      text,
  default_cta_text  text,
  color_from        text NOT NULL DEFAULT '#7C3AED',
  color_to          text NOT NULL DEFAULT '#4F46E5',
  text_color        text NOT NULL DEFAULT '#FFFFFF',
  animation         text DEFAULT 'fade',
  style_preset      text DEFAULT 'default',
  preview_image_url text,
  is_built_in       boolean NOT NULL DEFAULT false,
  is_active         boolean NOT NULL DEFAULT true,
  created_at        timestamp NOT NULL DEFAULT now(),
  updated_at        timestamp NOT NULL DEFAULT now()
);

-- ─── popup_campaigns ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS popup_campaigns (
  id                        text PRIMARY KEY,
  title                     text NOT NULL,
  body                      text,
  media_url                 text,
  cta_text                  text,
  cta_link                  text,
  popup_type                text NOT NULL DEFAULT 'modal',
  display_frequency         text NOT NULL DEFAULT 'once',
  max_impressions_per_user  integer DEFAULT 1,
  max_total_impressions     integer,
  priority                  integer NOT NULL DEFAULT 0,
  start_date                timestamp,
  end_date                  timestamp,
  timezone                  text DEFAULT 'Asia/Karachi',
  targeting                 jsonb DEFAULT '{}',
  status                    text NOT NULL DEFAULT 'draft',
  style_preset              text DEFAULT 'default',
  color_from                text DEFAULT '#7C3AED',
  color_to                  text DEFAULT '#4F46E5',
  text_color                text DEFAULT '#FFFFFF',
  animation                 text DEFAULT 'fade',
  template_id               text,
  created_by                text,
  created_at                timestamp NOT NULL DEFAULT now(),
  updated_at                timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS popup_campaigns_status_idx     ON popup_campaigns (status);
CREATE INDEX IF NOT EXISTS popup_campaigns_priority_idx   ON popup_campaigns (priority);
CREATE INDEX IF NOT EXISTS popup_campaigns_start_date_idx ON popup_campaigns (start_date);
CREATE INDEX IF NOT EXISTS popup_campaigns_end_date_idx   ON popup_campaigns (end_date);

-- ─── popup_impressions ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS popup_impressions (
  id         text PRIMARY KEY,
  popup_id   text NOT NULL,
  user_id    text NOT NULL,
  action     text NOT NULL DEFAULT 'view',
  seen_at    timestamp NOT NULL DEFAULT now(),
  session_id text
);
CREATE INDEX IF NOT EXISTS popup_impressions_popup_id_idx   ON popup_impressions (popup_id);
CREATE INDEX IF NOT EXISTS popup_impressions_user_id_idx    ON popup_impressions (user_id);
CREATE INDEX IF NOT EXISTS popup_impressions_popup_user_idx ON popup_impressions (popup_id, user_id);

-- ─── vendor_plans ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vendor_plans (
  id              text PRIMARY KEY,
  name            text NOT NULL,
  slug            text NOT NULL UNIQUE,
  description     text NOT NULL DEFAULT '',
  features_json   text NOT NULL DEFAULT '[]',
  commission_rate real NOT NULL DEFAULT 15,
  monthly_fee     real NOT NULL DEFAULT 0,
  max_products    integer NOT NULL DEFAULT 50,
  max_orders      integer NOT NULL DEFAULT 500,
  is_default      boolean NOT NULL DEFAULT false,
  is_active       boolean NOT NULL DEFAULT true,
  sort_order      integer NOT NULL DEFAULT 0,
  created_at      timestamp NOT NULL DEFAULT now(),
  updated_at      timestamp NOT NULL DEFAULT now()
);

-- ─── kyc_verifications additional
-- (already created above)

-- ─── popular_locations seed guard ────────────────────────────────────────────
-- (table created above, seed is in migration 0012)
