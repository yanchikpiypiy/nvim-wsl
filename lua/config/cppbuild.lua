-- Build the CMake project of the current file into the quickfix list. Keys: README "Build".

local chosen = {}

local function project_root()
    local found = vim.fs.find("CMakeLists.txt", {
        upward = true, limit = math.huge, path = vim.fn.expand("%:p:h"),
    })
    if #found == 0 then return nil end
    return vim.fs.dirname(found[#found])
end

local function build_dirs(root)
    local dirs = {}
    for name, kind in vim.fs.dir(root) do
        if kind == "directory" and name:match("^build") and
           vim.uv.fs_stat(root .. "/" .. name .. "/CMakeCache.txt") then
            table.insert(dirs, name)
        end
    end
    table.sort(dirs)
    return dirs
end

local function build_dir(root)
    if chosen[root] then return chosen[root] end
    local dirs = build_dirs(root)
    for _, d in ipairs(dirs) do if d == "build" then return d end end
    return dirs[1]
end

local function pick_build_dir()
    local root = project_root()
    if not root then return vim.notify("No CMakeLists.txt above this file", vim.log.levels.WARN) end
    local dirs = build_dirs(root)
    if #dirs == 0 then
        return vim.notify("No configured build dir in " .. root .. "\nRun: cmake -B build", vim.log.levels.WARN)
    end
    vim.ui.select(dirs, { prompt = "Build dir for " .. vim.fs.basename(root) }, function(choice)
        if choice then
            chosen[root] = choice
            vim.notify("Build dir set to " .. choice .. " — press <leader>mb to build")
        end
    end)
end

local function build()
    local root = project_root()
    if not root then return vim.notify("No CMakeLists.txt above this file", vim.log.levels.WARN) end
    local dir = build_dir(root)
    if not dir then
        return vim.notify("No configured build dir in " .. root .. "\nRun: cmake -B build", vim.log.levels.WARN)
    end

    vim.cmd("silent! wall")
    vim.notify("Building " .. vim.fs.basename(root) .. "/" .. dir .. " …")
    local t0 = vim.uv.hrtime()

    vim.system({ "cmake", "--build", dir }, { cwd = root, text = true }, function(res)
        vim.schedule(function()
            local lines = vim.split((res.stdout or "") .. (res.stderr or ""), "\n", { trimempty = true })
            local parsed = vim.fn.getqflist({ lines = lines, efm = vim.o.errorformat }).items
            local items = vim.tbl_filter(function(i) return i.valid == 1 end, parsed)
            vim.fn.setqflist({}, " ", { title = "cmake --build " .. dir, items = items })

            local errors, warnings = 0, 0
            for _, i in ipairs(items) do
                if i.text:match("^%s*f?a?t?a?l? ?error") or i.text:match("undefined reference") then
                    errors = errors + 1
                elseif i.text:match("^%s*warning") then
                    warnings = warnings + 1
                end
            end
            local secs = string.format("%.1fs", (vim.uv.hrtime() - t0) / 1e9)

            if res.code == 0 then
                vim.notify(("Build OK  (%s, %d warnings)"):format(secs, warnings), vim.log.levels.INFO)
                pcall(function() require("trouble").close("qflist") end)
            else
                vim.notify(("Build FAILED  (%s, %d errors, %d warnings)"):format(secs, errors, warnings),
                    vim.log.levels.WARN)
                if #items > 0 then
                    require("trouble").open("qflist")
                else
                    vim.fn.setqflist({}, " ", { title = "cmake --build " .. dir, lines = lines })
                    vim.cmd("copen")
                end
            end
        end)
    end)
end

local function qf_jump(cmd, wrap)
    if not pcall(vim.cmd, cmd) then pcall(vim.cmd, wrap) end
    vim.cmd("normal! zz")
end

local map = vim.keymap.set
map("n", "<leader>mb", build,          { silent = true, desc = "Build (cmake)" })
map("n", "<leader>md", pick_build_dir, { silent = true, desc = "Pick build dir" })
map("n", "<leader>mq", function() require("trouble").toggle("qflist") end,
    { silent = true, desc = "Toggle build errors" })
map("n", "]q", function() qf_jump("cnext", "cfirst") end, { silent = true, desc = "Next build error" })
map("n", "[q", function() qf_jump("cprev", "clast") end,  { silent = true, desc = "Prev build error" })

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        local root = project_root()
        local dir = root and build_dir(root)
        if root and dir then
            vim.opt_local.makeprg = "cmake --build " .. vim.fn.shellescape(root .. "/" .. dir)
        end
    end,
})

return { build = build, pick_build_dir = pick_build_dir }
