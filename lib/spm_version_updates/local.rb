def get_local_packages(where_to_search_local_packages)
  get_manifests(where_to_search_local_packages)
    .flat_map { |manifest| get_dependencies(manifest) }
end

def get_manifests(where_to_search_local_packages)
  # Do not parse files added at build phase
  Dir.glob("#{where_to_search_local_packages}/**/Package.swift")
    .reject { |manifest| manifest.start_with?("buildData/") }
end

def get_dependencies(manifest)
  content = File.read(manifest)
  package_name = package_name(content)
  get_requirement_kinds.each_with_object([]) { |kind, dependencies|
    regex = package_regex(kind)
    content.scan(regex).each { |match|
      url = match[0]
      requirement = {
        "kind" => process_kind_for_hash(kind),
        "package_name" => package_name
      }

      requirement["branch"] = match[1] if kind == "branch"
      requirement["maximumVersion"] = match[2] if kind == "range"
      requirement["revision"] = match[1] if kind == "revision"

      dependencies << [url, requirement]
    }
  }
end

def package_name(content)
  content.scan(/Package\(\s*name:\s*"([^"]+)"/).first.first
end

def get_requirement_kinds
  [
    "revision",
    "exact",
    "branch",
    "upToNextMajor",
    "upToNextMinor",
    "range"
  ]
end

def process_kind_for_hash(kind)
  case kind
  when "exact", "upToNextMinor", "upToNextMajor"
    "#{kind}Version"
  else
    kind
  end
end

def package_regex(req_kind)
  indent = '\s*'
  dot = '\.'
  less = '<'
  lp = /\(#{indent}/
  rp = /#{indent}\)/
  req_val = /"([^"]+)"/

  base = /#{dot}package#{lp}url:#{indent}#{req_val},#{indent}/

  req_arg = /#{req_kind}:#{indent}#{req_val}/   

  from = /from:#{indent}#{req_val}/
  up_to_next = /#{dot}#{req_kind}#{lp}#{from}#{rp}/
  any_major = /(?:#{up_to_next}|#{from})/

  excl_range = /#{dot}#{dot}#{less}/

  case req_kind
  when "exact", "branch", "revision"
    /#{base}#{req_arg}#{rp}/
  when "upToNextMajor"
    /#{base}#{any_major}#{rp}/
  when "upToNextMinor"
    /#{base}#{up_to_next}#{rp}/
  when "range"
    /#{base}#{req_val}#{excl_range}#{req_val}#{rp}/
  end
end
