-- Storage test suite. Runs Storage.create against fake environments (native bridge, an in-memory
-- file system, and neither), so it needs no executor. Run from the Studio command bar with
-- build/devserver.py running:
--   loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:8768/build/storage_tests.luau"))()(game.StarterGui.ScreenGui.Storage)
return function(storageModule)
	local HttpService = game:GetService("HttpService")
	local module = storageModule:Clone() -- a fresh copy so a cached require from an older version isn't used
	local Storage = require(module)
	local create = Storage.create

	local passed, failed = 0, {}
	local function check(label, cond)
		if cond then
			passed += 1
		else
			table.insert(failed, label)
		end
	end

	local function filesEnv(overrides)
		local files, folders = {}, {}
		local env = {
			writefile = function(p, c) files[p] = c end,
			readfile = function(p) assert(files[p], "no file " .. p) return files[p] end,
			isfile = function(p) return files[p] ~= nil end,
			isfolder = function(p) return folders[p] == true end,
			makefolder = function(p) folders[p] = true end,
			-- direct children only, files and folders, like a real executor
			listfiles = function(folder)
				local seen, out = {}, {}
				local prefix = folder .. "/"
				for p in files do
					if p:sub(1, #prefix) == prefix then
						local child = prefix .. p:sub(#prefix + 1):match("^[^/]+")
						if not seen[child] then
							seen[child] = true
							table.insert(out, child)
						end
					end
				end
				return out
			end,
			delfile = function(p) files[p] = nil end,
		}
		for k, v in overrides or {} do
			env[k] = v
		end
		return env, files, folders
	end

	local function nativeEnv(overrides)
		local accounts, current = {}, nil
		local env = {
			SetAccount = function(uid) current = uid accounts[uid] = accounts[uid] or {} end,
			ListScripts = function()
				local out = {}
				for name, e in accounts[current] do
					table.insert(out, {name = name, updated = e.updated})
				end
				return out
			end,
			SaveScript = function(name, code) accounts[current][name] = {code = code, updated = os.time()} return true end,
			LoadScript = function(name) local e = accounts[current][name] return e and e.code end,
			DeleteScript = function(name) local had = accounts[current][name] ~= nil accounts[current][name] = nil return had end,
		}
		for k, v in overrides or {} do
			env[k] = v
		end
		return env
	end

	local function favoriteOf(s, name)
		for _, r in s.list() do
			if r.name == name then
				return r.favorite
			end
		end
	end

	check("pick native", create(nativeEnv()).backend == "native")
	check("pick files", create((filesEnv())).backend == "files")
	check("pick memory", create({}).backend == "memory")
	local partial = filesEnv()
	partial.delfile = nil
	check("partial files -> memory", create(partial).backend == "memory")
	local mixed = filesEnv()
	mixed.SetAccount = function() end
	check("partial native + files -> files", create(mixed).backend == "files")
	check("module default in Studio is memory", Storage.backend == "memory")

	local function suite(kind, makeEnv)
		local s = create(makeEnv())
		local tag = kind .. ": "
		check(tag .. "backend", s.backend == kind)
		local ok, err = s.save("a", "x")
		check(tag .. "save before account", ok == false and err == "No account set")
		local rows, lerr = s.list()
		check(tag .. "list before account", #rows == 0 and lerr == "No account set")
		check(tag .. "load before account", s.load("a") == nil)
		check(tag .. "delete before account", s.delete("a") == false)
		check(tag .. "export before account", s.exportAll() == nil)
		check(tag .. "import before account", s.importAll("{}") == 0)
		check(tag .. "favorite before account", s.setFavorite("a", true) == false)
		for _, bad in {"abc", 1.5, nil, math.huge, 0 / 0} do
			check(tag .. "reject account " .. tostring(bad), s.setAccount(bad) == false)
		end
		local changes = 0
		s.changed:Connect(function() changes += 1 end)
		check(tag .. "setAccount", s.setAccount(1) == true)
		check(tag .. "save", s.save("a", "print(1)") == true)
		check(tag .. "load", s.load("a") == "print(1)")
		task.wait()
		check(tag .. "changed fired", changes >= 2)
		check(tag .. "overwrite", s.save("a", "print(2)") == true and s.load("a") == "print(2)" and #s.list() == 1)
		check(tag .. "empty name", s.save("", "x") == false)
		check(tag .. "blank name", s.save("   ", "x") == false)
		check(tag .. "64 chars ok", s.save(string.rep("n", 64), "x") == true)
		local ok65, err65 = s.save(string.rep("n", 65), "x")
		check(tag .. "65 chars rejected", ok65 == false and err65:find("too long") ~= nil)
		check(tag .. "64 emoji ok", s.save(string.rep("\u{1F525}", 64), "x") == true and s.load(string.rep("\u{1F525}", 64)) == "x")
		check(tag .. "65 emoji rejected", s.save(string.rep("\u{1F525}", 65), "x") == false)
		check(tag .. "slash", s.save("a/b", "x") == false)
		check(tag .. "backslash", s.save("a\\b", "x") == false)
		check(tag .. "dotdot", s.save("a..b", "x") == false)
		check(tag .. "single dot ok", s.save("v1.2", "x") == true)
		check(tag .. "leading dot reserved", s.save(".favorites", "x") == false and s.save(".hidden", "x") == false)
		check(tag .. "newline", s.save("a\nb", "x") == false)
		check(tag .. "quotes ok", s.save('he said "hi" \'ok\'', "q") == true and s.load('he said "hi" \'ok\'') == "q")
		check(tag .. "non-string name", s.save(123, "x") == false)
		check(tag .. "trimmed", s.save("  spaced  ", "t") == true and s.load("spaced") == "t")
		check(tag .. "invalid utf8", s.save("\255\254", "x") == false)
		check(tag .. "exactly 500KB", s.save("big", string.rep("a", 500 * 1024)) == true)
		check(tag .. "500KB + 1", s.save("big2", string.rep("a", 500 * 1024 + 1)) == false)
		check(tag .. "non-string code", s.save("c", 5) == false)
		local dok, derr = s.delete("missing")
		check(tag .. "delete missing", dok == false and type(derr) == "string")
		check(tag .. "delete", s.delete("big") == true and s.load("big") == nil)

		check(tag .. "favorite", s.setFavorite("a", true) == true)
		check(tag .. "row shows favorite", favoriteOf(s, "a") == true)
		check(tag .. "favorite record hidden from list", (function()
			for _, r in s.list() do
				if r.name:sub(1, 1) == "." then
					return false
				end
			end
			return true
		end)())
		check(tag .. "favorite missing script", s.setFavorite("nope", true) == false)
		check(tag .. "can't load favorites record", s.load(".favorites") == nil)
		check(tag .. "unfavorite", s.setFavorite("a", false) == true and favoriteOf(s, "a") == false)
		s.setFavorite("spaced", true)
		s.delete("spaced")
		s.save("spaced", "again")
		check(tag .. "delete clears favorite", favoriteOf(s, "spaced") == false)

		s.setAccount(2)
		check(tag .. "B sees nothing", #s.list() == 0 and s.load("a") == nil)
		s.save("b-only", "b")
		s.setFavorite("b-only", true)
		s.setAccount(1)
		check(tag .. "A can't see B", s.load("b-only") == nil and s.load("a") == "print(2)")
		check(tag .. "favorites per account", (function()
			for _, r in s.list() do
				if r.favorite then
					return false
				end
			end
			return true
		end)())

		s.setAccount(3)
		local all = true
		for i = 1, 500 do
			if s.save("s" .. i, "x") ~= true then
				all = false
			end
		end
		check(tag .. "500 scripts", all and #s.list() == 500)
		local ok501, err501 = s.save("s501", "x")
		check(tag .. "501st rejected", ok501 == false and err501:find("500") ~= nil)
		check(tag .. "overwrite when full", s.save("s1", "y") == true)
		check(tag .. "favorite when full", s.setFavorite("s1", true) == true and s.save("s501", "x") == false)

		s.setAccount(4)
		s.save("one", "1")
		s.save("two", "2")
		s.setFavorite("two", true)
		local json = s.exportAll()
		local decoded = HttpService:JSONDecode(json)
		check(tag .. "export format", decoded.version == 1 and decoded.account == 4 and #decoded.scripts == 2 and decoded.scripts[1].code ~= nil)
		s.setAccount(5)
		check(tag .. "import count", s.importAll(json) == 2 and s.load("one") == "1" and s.load("two") == "2")
		check(tag .. "import carries favorite", favoriteOf(s, "two") == true)
		check(tag .. "re-import is a no-op", s.importAll(json) == 0)
		check(tag .. "import bad json", s.importAll("not json") == 0)
		check(tag .. "import wrong shape", s.importAll('{"a":1}') == 0)
		check(tag .. "import non-string", s.importAll(nil) == 0)
		local skipCount, skipMsg = s.importAll(HttpService:JSONEncode({scripts = {{name = "../x", code = "x", updated = 1}, {name = "ok", code = 5}}}))
		check(tag .. "import skips bad entries", skipCount == 0 and skipMsg ~= nil)

		if kind ~= "native" then -- the bridge stamps its own times, so merge by time only applies to files/memory
			s.setAccount(6)
			s.save("keep", "local-new")
			s.save("replace", "local-old")
			local now = os.time()
			local merge = HttpService:JSONEncode({scripts = {
				{name = "keep", code = "import-old", updated = 1},
				{name = "replace", code = "import-new", updated = now + 100},
				{name = "fresh", code = "f", updated = 5},
			}})
			check(tag .. "merge count", s.importAll(merge) == 2)
			check(tag .. "merge keeps newer local", s.load("keep") == "local-new")
			check(tag .. "merge takes newer import", s.load("replace") == "import-new")
			check(tag .. "merge adds new", s.load("fresh") == "f")
			check(tag .. "list newest first", s.list()[1].name == "replace")
		end

		s.setAccount(7)
		s.save("x7", "7")
		s.setAccount(8)
		check(tag .. "no cross-account after switch", s.load("x7") == nil)
	end

	suite("native", nativeEnv)
	suite("files", function() return (filesEnv()) end)
	suite("memory", function() return {} end)

	local tf = create(filesEnv({writefile = function() error("disk full") end}))
	tf.setAccount(1)
	local tok, terr = tf.save("a", "x")
	check("files throw -> false + message", tok == false and terr:find("disk full") ~= nil)
	local tn = create(nativeEnv({SaveScript = function() error("bridge down") end}))
	tn.setAccount(1)
	local nok, nerr = tn.save("a", "x")
	check("native throw -> false + message", nok == false and nerr:find("bridge down") ~= nil)
	local tl = create(nativeEnv({ListScripts = function() error("nope") end}))
	tl.setAccount(1)
	local lrows, lerr2 = tl.list()
	check("native list throw -> {} + message", #lrows == 0 and lerr2 ~= nil)
	local sf = create(nativeEnv({SaveScript = function() return false, "quota" end}))
	sf.setAccount(1)
	local qok, qerr = sf.save("a", "x")
	check("native returns false -> message passed on", qok == false and qerr:find("quota") ~= nil)
	local sa = create(nativeEnv({SetAccount = function() error("bad") end}))
	check("native SetAccount throw -> false", sa.setAccount(1) == false and sa.save("a", "x") == false)
	local lf = create(nativeEnv({LoadScript = function() error("load broke") end}))
	lf.setAccount(1)
	lf.save("a", "x")
	check("favorites read failure doesn't break list", #lf.list() == 1)

	local cenv, cfiles = filesEnv()
	cfiles["accounts/1/index.json"] = "{garbage"
	local cs = create(cenv)
	cs.setAccount(1)
	check("corrupt index -> empty list", #cs.list() == 0)
	check("corrupt index backed up", cfiles["accounts/1/index.json.bad"] == "{garbage")
	check("save after corrupt index", cs.save("a", "x") == true and cs.load("a") == "x")

	local nenv, nfiles = filesEnv()
	local ns = create(nenv)
	ns.setAccount(9)
	ns.save("Test", "1")
	ns.save("test", "2")
	ns.save("\u{1F525}", "3")
	ns.setFavorite("test", true)
	check("case-clash names stay separate", ns.load("Test") == "1" and ns.load("test") == "2")
	check("readable file name", nfiles["accounts/9/scripts/Test.lua"] == "1")
	check("index persisted", nfiles["accounts/9/index.json"] ~= nil)
	local ns2 = create(nenv)
	ns2.setAccount(9)
	check("reload from disk", ns2.load("\u{1F525}") == "3" and #ns2.list() == 3)
	check("favorites reload from disk", favoriteOf(ns2, "test") == true)
	ns2.delete("Test")
	check("delete removes file", nfiles["accounts/9/scripts/Test.lua"] == nil)

	-- accounts on this device: listing, copying between accounts, clearing
	for _, kind in {"files", "memory"} do
		local s = create(kind == "files" and (filesEnv()) or {})
		s.setAccount(10)
		s.save("a", "1")
		s.save("b", "2")
		s.setFavorite("a", true)
		s.setAccount(11)
		s.save("c", "3")
		s.setAccount(12)
		local list = s.accounts()
		check(kind .. ": accounts lists the signed-in one first", list[1] and list[1].userId == 12 and list[1].current == true and list[1].count == 0)
		check(kind .. ": accounts includes others with saves", #list == 3)
		check(kind .. ": copyFrom brings scripts over", s.copyFrom(10) == 2 and s.load("a") == "1" and s.load("b") == "2")
		check(kind .. ": copyFrom keeps favorites", favoriteOf(s, "a") == true)
		check(kind .. ": copyFrom leaves the source alone", (function()
			s.setAccount(10)
			local n = #s.list()
			s.setAccount(12)
			return n == 2
		end)())
		check(kind .. ": copyFrom self refused", s.copyFrom(12) == 0)
		check(kind .. ": copyFrom bad id refused", s.copyFrom("nope") == 0)
		local okClear, removed = s.clearAccount(11)
		check(kind .. ": clearAccount another account", okClear == true and removed == 1)
		check(kind .. ": cleared account leaves the list", #s.accounts() == 2)
		local okClear2, removed2 = s.clearAccount()
		check(kind .. ": clearAccount the signed-in one", okClear2 == true and removed2 == 2 and #s.list() == 0)
		check(kind .. ": signed-in account still listed when empty", s.accounts()[1].userId == 12)
	end
	local nativeStore = create(nativeEnv())
	nativeStore.setAccount(5)
	nativeStore.save("x", "1")
	check("native: accounts is just the signed-in one", #nativeStore.accounts() == 1 and nativeStore.accounts()[1].count == 1)
	check("native: copyFrom refused", nativeStore.copyFrom(6) == 0)
	check("native: clearAccount of another refused", nativeStore.clearAccount(6) == false)
	check("native: clearAccount of the signed-in one", select(2, nativeStore.clearAccount()) == 1 and #nativeStore.list() == 0)
	local fresh = create({})
	check("before account: accounts empty, copy/clear refused", #fresh.accounts() == 0 and fresh.copyFrom(1) == 0 and fresh.clearAccount(1) == false)

	module:Destroy()
	return passed .. " passed, " .. #failed .. " failed" .. (#failed > 0 and (":\n" .. table.concat(failed, "\n")) or "")
end
