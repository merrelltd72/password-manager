# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'json'
module Exports
  class FileBuilder
    def self.call(run:)
      new(run).call
    end

    def initialize(run)
      @run = run
      @user = run.user
    end

    def call
      rows = @user.accounts.order(:id).pluck(:id, :web_app_name, :url, :username, :notes)
      {
        path: build_file(rows),
        record_count: rows.size,
        expires_at: 7.days.from_now
      }
    end

    private

    def build_file(rows)
      case @run.format
      when 'csv' then write_csv(rows)
      when 'json' then write_json(rows)
      when 'xlsx' then write_xlsx(rows)
      else
        raise ArgumentError, "Unsupported format: #{@run.format}"
      end
    end

    def write_csv(rows)
      dir = Rails.root.join('tmp', 'exports', @user.id.to_s)
      FileUtils.mkdir_p(dir)
      path = dir.join("export_#{@run.id}.csv")

      CSV.open(path, 'wb') do |csv|
        csv << %w[id web_app_name url username notes]
        rows.each { |row| csv << row }
      end

      path.to_s
    end

    def write_json(rows)
      dir = Rails.root.join('tmp', 'exports', @user.id.to_s)
      FileUtils.mkdir_p(dir)
      path = dir.join("export_#{@run.id}.json")

      payload = rows.map do |id, web_app_name, url, username, notes|
        { id: id, web_app_name: web_app_name, url: url, username: username, notes: notes }
      end

      File.write(path, JSON.pretty_generate(payload))
      path.to_s
    end

    def write_xlsx(rows)
      # Implement this functionality
      raise NotImplementedError, 'xlsx writer not implemented yet'
    end
  end
end
