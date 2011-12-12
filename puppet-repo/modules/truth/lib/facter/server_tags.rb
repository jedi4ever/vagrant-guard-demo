Facter.add("server_tags") do
  setcode do
    tags=File.readlines("/data/etc/server_tags").map{|line| line.strip}.join(",")
    tags
  end
end
