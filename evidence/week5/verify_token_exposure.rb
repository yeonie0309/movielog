#!/usr/bin/env ruby

# Prints only pass/fail facts. Never prints the token or .env contents.
require 'open3'

env_path = '.env'
abort 'FAIL: .env 파일이 없습니다.' unless File.file?(env_path)

line = File.foreach(env_path).find { |entry| entry.start_with?('TMDB_ACCESS_TOKEN=') }
token = line&.split('=', 2)&.last&.strip
abort 'FAIL: TMDB_ACCESS_TOKEN이 비어 있습니다.' if token.nil? || token.empty?

tracked, status = Open3.capture2('git', 'ls-files', '-z')
abort 'FAIL: Git 추적 파일을 읽지 못했습니다.' unless status.success?
paths = tracked.split("\0")
abort 'FAIL: .env가 Git에 추적되고 있습니다.' if paths.include?(env_path)

leaks = paths.select { |path| File.file?(path) && File.binread(path).include?(token) }
abort "FAIL: 토큰이 Git 추적 파일 #{leaks.length}개에서 발견됐습니다." unless leaks.empty?

ignored, ignore_status = Open3.capture2('git', 'check-ignore', env_path)
abort 'FAIL: .env가 .gitignore에 의해 제외되지 않습니다.' unless ignore_status.success? && ignored.strip == env_path

puts 'PASS: .env는 Git에서 무시되며 추적되지 않습니다.'
puts "PASS: 현재 Git 추적 파일 #{paths.length}개에서 TMDB 토큰 원문이 발견되지 않았습니다."
puts '참고: 이 검사는 로컬 Git 파일을 확인합니다. 영상의 시각적 노출은 별도로 검토해야 합니다.'
