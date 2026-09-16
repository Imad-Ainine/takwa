## Table `achievements`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `user_id` | `uuid` |  Nullable |
| `type` | `text` |  |
| `title_ar` | `text` |  Nullable |
| `desc_ar` | `text` |  Nullable |
| `emoji` | `text` |  Nullable |
| `points_reward` | `int4` |  Nullable |
| `earned_at` | `timestamptz` |  Nullable |

## Table `adhkar`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `category` | `text` |  |
| `title` | `text` |  |
| `text` | `text` |  |
| `translation` | `text` |  Nullable |
| `benefits` | `text` |  Nullable |
| `recommended_count` | `int4` |  Nullable |
| `sort_order` | `int4` |  Nullable |
| `source` | `text` |  Nullable |
| `code` | `int4` |  Nullable |
| `category_id` | `uuid` |  Nullable |

## Table `adhkar_categories`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name_ar` | `text` |  |
| `emoji` | `text` |  Nullable |
| `sort_order` | `int4` |  Nullable |

## Table `asma_allah`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `number` | `int4` | Primary |
| `name` | `text` |  |
| `transliteration` | `text` |  Nullable |
| `meaning` | `text` |  Nullable |
| `explanation` | `text` |  Nullable |
| `dua` | `text` |  Nullable |
| `quran_ref` | `text` |  Nullable |

## Table `book_reading_progress`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `book_id` | `text` |  |
| `chapter_index` | `int4` |  |
| `page_index` | `int4` |  |
| `read_pages` | `jsonb` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `pdf_page` | `int4` |  |
| `total_pdf_pages` | `int4` |  |
| `reading_seconds` | `int8` |  |

## Table `books`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `title_ar` | `text` |  |
| `title_en` | `text` |  |
| `author_ar` | `text` |  |
| `author_en` | `text` |  |
| `description_ar` | `text` |  |
| `emoji` | `text` |  Nullable |
| `category` | `text` |  |
| `cover_url` | `text` |  Nullable |
| `pdf_url` | `text` |  Nullable |
| `publish_year` | `int4` |  Nullable |
| `cover_color` | `text` |  Nullable |
| `cover_color_2` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `community_adhkar`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `shared_by` | `uuid` |  Nullable |
| `text_ar` | `text` |  |
| `count` | `int4` |  Nullable |
| `category_hint` | `text` |  Nullable |
| `likes` | `int4` |  Nullable |
| `approved` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `community_duas`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `shared_by` | `uuid` |  Nullable |
| `title_ar` | `text` |  |
| `text_ar` | `text` |  |
| `occasion` | `text` |  Nullable |
| `source` | `text` |  Nullable |
| `emoji` | `text` |  Nullable |
| `likes` | `int4` |  Nullable |
| `approved` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `custom_ibadah`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `user_id` | `uuid` | Primary |
| `name_ar` | `text` |  |
| `emoji` | `text` |  Nullable |
| `is_positive` | `bool` |  Nullable |
| `points` | `int4` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `sort_order` | `int4` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `custom_ibadah_log`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  Nullable |
| `ibadah_id` | `int4` |  |
| `date` | `date` |  |
| `done` | `bool` |  Nullable |
| `count` | `int4` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `daily_records`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `user_id` | `uuid` | Primary |
| `date` | `date` | Primary |
| `fajr_status` | `text` |  Nullable |
| `dhuhr_status` | `text` |  Nullable |
| `asr_status` | `text` |  Nullable |
| `maghrib_status` | `text` |  Nullable |
| `isha_status` | `text` |  Nullable |
| `night_prayer` | `bool` |  Nullable |
| `witr` | `bool` |  Nullable |
| `rawatib` | `int4` |  Nullable |
| `quran_pages` | `int4` |  Nullable |
| `quran_verses` | `int4` |  Nullable |
| `quran_juzaa` | `float4` |  Nullable |
| `morning_adhkar` | `bool` |  Nullable |
| `evening_adhkar` | `bool` |  Nullable |
| `after_prayer_adhkar` | `bool` |  Nullable |
| `tasbeeh_count` | `int4` |  Nullable |
| `fasting_type` | `text` |  Nullable |
| `sadaqah` | `bool` |  Nullable |
| `sadaqah_amount` | `float4` |  Nullable |
| `net_points` | `int4` |  Nullable |
| `taqwa_points` | `int4` |  Nullable |
| `deducted_points` | `int4` |  Nullable |
| `mood` | `text` |  Nullable |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `douaa_categories`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name_ar` | `text` |  |
| `emoji` | `text` |  Nullable |
| `sort_order` | `int4` |  Nullable |

## Table `douaa_content`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `category_id` | `uuid` |  Nullable |
| `title_ar` | `text` |  |
| `text_ar` | `text` |  |
| `reference` | `text` |  Nullable |
| `sort_order` | `int4` |  Nullable |

## Table `profiles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `username` | `text` |  Nullable |
| `email` | `text` |  Nullable |
| `avatar_emoji` | `text` |  Nullable |
| `gender` | `text` |  Nullable |
| `total_points` | `int4` |  Nullable |
| `current_streak` | `int4` |  Nullable |
| `highest_streak` | `int4` |  Nullable |
| `quran_pages` | `int4` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `prohibitions_log`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  Nullable |
| `record_id` | `int4` |  Nullable |
| `date` | `date` |  |
| `category` | `text` |  |
| `committed` | `bool` |  Nullable |
| `times_count` | `int4` |  Nullable |
| `deduct_points` | `int4` |  Nullable |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `reminders`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `local_id` | `int4` |  |
| `title` | `text` |  |
| `icon_name` | `text` |  |
| `time` | `text` |  |
| `is_enabled` | `bool` |  |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `user_adhkar`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  Nullable |
| `text_ar` | `text` |  |
| `count` | `int4` |  Nullable |
| `category_hint` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `user_duas`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  Nullable |
| `title_ar` | `text` |  |
| `text_ar` | `text` |  |
| `occasion` | `text` |  Nullable |
| `source` | `text` |  Nullable |
| `emoji` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `user_settings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `user_id` | `uuid` | Primary |
| `madhab` | `text` |  Nullable |
| `ramadan_mode` | `text` |  Nullable |
| `calc_method` | `text` |  Nullable |
| `prayer_reminder` | `text` |  Nullable |
| `muhasaba_reminder` | `text` |  Nullable |
| `evening_reminder_time` | `text` |  Nullable |
| `language` | `text` |  Nullable |
| `wake_up_before_fajr` | `text` |  Nullable |
| `morning_adhkar_reminder` | `text` |  Nullable |
| `evening_adhkar_reminder` | `text` |  Nullable |
| `favorite_adhkar` | `jsonb` |  Nullable |
| `favorite_duas` | `jsonb` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `pre_adhan_notif` | `bool` |  Nullable |
| `iqama_notif` | `bool` |  Nullable |
| `wake_up_time` | `text` |  Nullable |
| `daily_duas_on` | `bool` |  Nullable |
| `special_reminders_on` | `bool` |  Nullable |
| `fasting_reminders_on` | `bool` |  Nullable |
| `theme_mode` | `text` |  Nullable |
| `adhkar_notif_enabled` | `bool` |  Nullable |
| `morning_adhkar_time` | `text` |  Nullable |
| `evening_adhkar_time` | `text` |  Nullable |
| `sleep_adhkar_time` | `text` |  Nullable |
| `after_fajr_adhkar` | `bool` |  Nullable |
| `after_asr_adhkar` | `bool` |  Nullable |
| `adhan_sound` | `text` |  Nullable |
| `overlay_popups_enabled` | `bool` |  Nullable |
| `adhan_sound_enabled` | `bool` |  Nullable |
| `adhan_screen_enabled` | `bool` |  Nullable |
| `popup_interval_minutes` | `int4` |  Nullable |
| `adhan_mode` | `text` |  Nullable |
| `adhan_volume_level` | `float8` |  Nullable |
| `silent_mode_enabled` | `bool` |  Nullable |
| `silent_vibration_enabled` | `bool` |  Nullable |
| `silent_mode_alert_style` | `text` |  Nullable |
| `silent_adhan_prayers` | `text` |  Nullable |
| `silent_notif_prayers` | `text` |  Nullable |
| `flip_to_silence_enabled` | `bool` |  Nullable |
| `adhan_alarm_enabled` | `bool` |  Nullable |
| `wake_screen_enabled` | `bool` |  Nullable |
| `ongoing_notif_enabled` | `bool` |  Nullable |
| `auto_silent_after_adhan` | `bool` |  Nullable |
| `adhan_in_silent_enabled` | `bool` |  Nullable |
| `notifs_in_silent_enabled` | `bool` |  Nullable |
| `vibrate_with_adhan` | `bool` |  Nullable |
| `silent_duration_mins` | `int4` |  Nullable |
| `high_latitude_rule` | `text` |  Nullable |
| `fajr_offset` | `int4` |  Nullable |
| `sunrise_offset` | `int4` |  Nullable |
| `dhuhr_offset` | `int4` |  Nullable |
| `asr_offset` | `int4` |  Nullable |
| `maghrib_offset` | `int4` |  Nullable |
| `isha_offset` | `int4` |  Nullable |
