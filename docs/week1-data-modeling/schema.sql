-- UMC PE 1주차: 요구사항을 데이터로 바꾸기
-- Target: MySQL 8.0.16+

CREATE TABLE members (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    region_id BIGINT UNSIGNED NOT NULL,
    email VARCHAR(255) NULL,
    name VARCHAR(50) NOT NULL,
    nickname VARCHAR(30) NOT NULL,
    phone_number VARCHAR(20) NULL,
    gender VARCHAR(20) NOT NULL,
    birth_date DATE NOT NULL,
    address_detail VARCHAR(255) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_members_email (email),
    UNIQUE KEY uk_members_nickname (nickname),
    KEY ix_members_region_id (region_id),
    CONSTRAINT ck_members_gender
        CHECK (gender IN ('female', 'male', 'other')),
    CONSTRAINT ck_members_status
        CHECK (status IN ('active', 'inactive', 'withdrawn'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE social_accounts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    member_id BIGINT UNSIGNED NOT NULL,
    provider VARCHAR(20) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_social_accounts_provider_user (provider, provider_user_id),
    UNIQUE KEY uk_social_accounts_member_provider (member_id, provider),
    CONSTRAINT ck_social_accounts_provider
        CHECK (provider IN ('kakao', 'naver', 'google', 'apple')),
    CONSTRAINT fk_social_accounts_member
        FOREIGN KEY (member_id) REFERENCES members (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE regions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    parent_region_id BIGINT UNSIGNED NULL,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(50) NOT NULL,
    depth TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_regions_code (code),
    KEY ix_regions_parent_region_id (parent_region_id),
    CONSTRAINT ck_regions_depth CHECK (depth BETWEEN 1 AND 3),
    CONSTRAINT fk_regions_parent_region
        FOREIGN KEY (parent_region_id) REFERENCES regions (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE food_categories (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(50) NOT NULL,
    display_order INT UNSIGNED NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_food_categories_code (code),
    UNIQUE KEY uk_food_categories_name (name)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

ALTER TABLE members
    ADD CONSTRAINT fk_members_region
    FOREIGN KEY (region_id) REFERENCES regions (id)
    ON UPDATE RESTRICT ON DELETE RESTRICT;

CREATE TABLE terms (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    content_url VARCHAR(2048) NOT NULL,
    version VARCHAR(20) NOT NULL,
    is_required BOOLEAN NOT NULL,
    effective_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_terms_title_version (title, version)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE member_terms (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    member_id BIGINT UNSIGNED NOT NULL,
    term_id BIGINT UNSIGNED NOT NULL,
    is_agreed BOOLEAN NOT NULL,
    agreed_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_member_terms_member_term (member_id, term_id),
    KEY ix_member_terms_term_id (term_id),
    CONSTRAINT ck_member_terms_agreed_at
        CHECK (is_agreed = FALSE OR agreed_at IS NOT NULL),
    CONSTRAINT fk_member_terms_member
        FOREIGN KEY (member_id) REFERENCES members (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_member_terms_term
        FOREIGN KEY (term_id) REFERENCES terms (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE member_food_categories (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    member_id BIGINT UNSIGNED NOT NULL,
    food_category_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_member_food_categories_member_category
        (member_id, food_category_id),
    KEY ix_member_food_categories_food_category_id (food_category_id),
    CONSTRAINT fk_member_food_categories_member
        FOREIGN KEY (member_id) REFERENCES members (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_member_food_categories_food_category
        FOREIGN KEY (food_category_id) REFERENCES food_categories (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE stores (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    region_id BIGINT UNSIGNED NOT NULL,
    food_category_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    description VARCHAR(500) NULL,
    image_url VARCHAR(2048) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    KEY ix_stores_region_id (region_id),
    KEY ix_stores_food_category_id (food_category_id),
    CONSTRAINT ck_stores_status CHECK (status IN ('open', 'temporarily_closed', 'closed')),
    CONSTRAINT fk_stores_region
        FOREIGN KEY (region_id) REFERENCES regions (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_stores_food_category
        FOREIGN KEY (food_category_id) REFERENCES food_categories (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE missions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    store_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(100) NOT NULL,
    description VARCHAR(500) NOT NULL,
    minimum_order_amount DECIMAL(10, 2) NULL,
    reward_points INT UNSIGNED NOT NULL,
    started_at DATETIME(6) NULL,
    ended_at DATETIME(6) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    KEY ix_missions_store_id (store_id),
    CONSTRAINT ck_missions_reward_points CHECK (reward_points > 0),
    CONSTRAINT ck_missions_period
        CHECK (ended_at IS NULL OR started_at IS NULL OR ended_at > started_at),
    CONSTRAINT ck_missions_status CHECK (status IN ('draft', 'active', 'ended')),
    CONSTRAINT fk_missions_store
        FOREIGN KEY (store_id) REFERENCES stores (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE member_missions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    member_id BIGINT UNSIGNED NOT NULL,
    mission_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'accepted',
    verification_code VARCHAR(100) NULL,
    verification_requested_at DATETIME(6) NULL,
    accepted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    completed_at DATETIME(6) NULL,
    claimed_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_member_missions_member_mission (member_id, mission_id),
    KEY ix_member_missions_mission_id (mission_id),
    KEY ix_member_missions_member_status (member_id, status),
    CONSTRAINT ck_member_missions_status
        CHECK (status IN (
            'accepted', 'in_progress', 'verification_requested',
            'completed', 'claimed', 'expired'
        )),
    CONSTRAINT ck_member_missions_verification
        CHECK (
            status <> 'verification_requested'
            OR verification_requested_at IS NOT NULL
        ),
    CONSTRAINT ck_member_missions_completed_at
        CHECK (status NOT IN ('completed', 'claimed') OR completed_at IS NOT NULL),
    CONSTRAINT ck_member_missions_claimed_at
        CHECK (status <> 'claimed' OR claimed_at IS NOT NULL),
    CONSTRAINT fk_member_missions_member
        FOREIGN KEY (member_id) REFERENCES members (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_member_missions_mission
        FOREIGN KEY (mission_id) REFERENCES missions (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE reviews (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    member_mission_id BIGINT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL,
    content VARCHAR(1000) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'published',
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_reviews_member_mission_id (member_mission_id),
    CONSTRAINT ck_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT ck_reviews_status CHECK (status IN ('published', 'hidden')),
    CONSTRAINT fk_reviews_member_mission
        FOREIGN KEY (member_mission_id) REFERENCES member_missions (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE review_images (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    review_id BIGINT UNSIGNED NOT NULL,
    image_url VARCHAR(2048) NOT NULL,
    display_order INT UNSIGNED NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uk_review_images_review_order (review_id, display_order),
    CONSTRAINT fk_review_images_review
        FOREIGN KEY (review_id) REFERENCES reviews (id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
