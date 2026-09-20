-- UMC PE 2주차: SQL로 데이터 다루기
-- 공통 온라인 도서 대여 관리 시스템 스키마
-- Target: MySQL 8.0+

DROP DATABASE IF EXISTS umc_week2_library;
CREATE DATABASE umc_week2_library
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE umc_week2_library;

CREATE TABLE users (
    user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nickname VARCHAR(30) NOT NULL,
    PRIMARY KEY (user_id),
    UNIQUE KEY uk_users_nickname (nickname)
) ENGINE = InnoDB;

CREATE TABLE category (
    category_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uk_category_name (name)
) ENGINE = InnoDB;

CREATE TABLE book (
    book_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (book_id),
    KEY ix_book_category_id (category_id),
    CONSTRAINT fk_book_category
        FOREIGN KEY (category_id) REFERENCES category (category_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE rental (
    rental_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    book_id BIGINT UNSIGNED NOT NULL,
    rented_at DATETIME NOT NULL,
    due_at DATETIME NOT NULL,
    returned_at DATETIME NULL,
    PRIMARY KEY (rental_id),
    KEY ix_rental_user_id (user_id),
    KEY ix_rental_book_id (book_id),
    CONSTRAINT ck_rental_due_at CHECK (due_at > rented_at),
    CONSTRAINT ck_rental_returned_at
        CHECK (returned_at IS NULL OR returned_at >= rented_at),
    CONSTRAINT fk_rental_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_rental_book
        FOREIGN KEY (book_id) REFERENCES book (book_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE tag (
    tag_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL,
    PRIMARY KEY (tag_id),
    UNIQUE KEY uk_tag_name (name)
) ENGINE = InnoDB;

CREATE TABLE book_tag (
    book_id BIGINT UNSIGNED NOT NULL,
    tag_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (book_id, tag_id),
    KEY ix_book_tag_tag_id (tag_id),
    CONSTRAINT fk_book_tag_book
        FOREIGN KEY (book_id) REFERENCES book (book_id)
        ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT fk_book_tag_tag
        FOREIGN KEY (tag_id) REFERENCES tag (tag_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE book_like (
    user_id BIGINT UNSIGNED NOT NULL,
    book_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (user_id, book_id),
    KEY ix_book_like_book_id (book_id),
    CONSTRAINT fk_book_like_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT fk_book_like_book
        FOREIGN KEY (book_id) REFERENCES book (book_id)
        ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE notification (
    notification_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    type VARCHAR(30) NOT NULL,
    PRIMARY KEY (notification_id),
    KEY ix_notification_user_id (user_id),
    CONSTRAINT fk_notification_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE = InnoDB;
