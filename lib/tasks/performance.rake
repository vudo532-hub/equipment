# frozen_string_literal: true

namespace :performance do
  desc "Показать статистику использования индексов PostgreSQL"
  task index_stats: :environment do
    puts "=== Статистика индексов ==="
    puts ""

    results = ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT
        schemaname,
        relname AS table_name,
        indexrelname AS index_name,
        idx_scan AS scans,
        idx_tup_read AS tuples_read,
        idx_tup_fetch AS tuples_fetched,
        pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
      FROM pg_stat_user_indexes
      ORDER BY idx_scan DESC
    SQL

    puts format("%-30s %-45s %10s %12s %s", "Таблица", "Индекс", "Сканирований", "Прочитано", "Размер")
    puts "-" * 120

    results.each do |row|
      puts format("%-30s %-45s %10s %12s %s",
        row["table_name"],
        row["index_name"],
        row["scans"],
        row["tuples_read"],
        row["index_size"]
      )
    end

    puts ""
    puts "=== Неиспользуемые индексы (0 сканирований) ==="
    unused = results.select { |r| r["scans"].to_i == 0 }
    if unused.any?
      unused.each do |row|
        puts "  #{row['table_name']}.#{row['index_name']} (#{row['index_size']})"
      end
    else
      puts "  Все индексы используются."
    end
  end

  desc "Показать размеры таблиц"
  task table_sizes: :environment do
    puts "=== Размеры таблиц ==="
    puts ""

    results = ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT
        relname AS table_name,
        n_live_tup AS row_count,
        pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
        pg_size_pretty(pg_relation_size(relid)) AS table_size,
        pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_size
      FROM pg_stat_user_tables
      ORDER BY pg_total_relation_size(relid) DESC
    SQL

    puts format("%-35s %10s %12s %12s %12s", "Таблица", "Строк", "Всего", "Данные", "Индексы")
    puts "-" * 90

    results.each do |row|
      puts format("%-35s %10s %12s %12s %12s",
        row["table_name"],
        row["row_count"],
        row["total_size"],
        row["table_size"],
        row["index_size"]
      )
    end
  end

  desc "Показать медленные запросы (требуется pg_stat_statements)"
  task slow_queries: :environment do
    puts "=== Медленные запросы ==="
    puts ""

    begin
      results = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT
          round(total_exec_time::numeric, 2) AS total_time_ms,
          calls,
          round(mean_exec_time::numeric, 2) AS avg_time_ms,
          round(max_exec_time::numeric, 2) AS max_time_ms,
          left(query, 120) AS query
        FROM pg_stat_statements
        WHERE userid = (SELECT usesysid FROM pg_user WHERE usename = current_user)
        ORDER BY mean_exec_time DESC
        LIMIT 20
      SQL

      puts format("%-12s %-8s %-12s %-12s %s", "Всего (ms)", "Вызовов", "Среднее", "Макс", "Запрос")
      puts "-" * 120

      results.each do |row|
        puts format("%-12s %-8s %-12s %-12s %s",
          row["total_time_ms"],
          row["calls"],
          row["avg_time_ms"],
          row["max_time_ms"],
          row["query"]
        )
      end
    rescue ActiveRecord::StatementInvalid => e
      puts "  pg_stat_statements не установлен."
      puts "  Для активации добавьте в postgresql.conf:"
      puts "    shared_preload_libraries = 'pg_stat_statements'"
      puts "  И выполните: CREATE EXTENSION pg_stat_statements;"
    end
  end

  desc "Полный отчёт о производительности"
  task report: [:table_sizes, :index_stats] do
    puts ""
    puts "=== Конфигурация Rails ==="
    puts "  Среда: #{Rails.env}"
    puts "  Кэш: #{Rails.cache.class.name}"
    puts "  Пул БД: #{ActiveRecord::Base.connection_pool.size}"
    puts "  Gzip: #{Rails.application.config.middleware.include?(Rack::Deflater) ? 'Да' : 'Нет'}"
    puts ""
  end
end
