-- ==========================================
-- Lazy.nvim 完整配置示例
-- 包含im_switch.nvim和自动更新/测试配置
-- ==========================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================
-- Lazy.nvim 基础配置
-- ==========================================
require("lazy").setup({
  spec = {
    -- ==========================================
    -- im_switch.nvim 配置
    -- ==========================================
    {
      -- 开发阶段：使用本地路径
      dir = vim.fn.expand("~/data/repo/input/im_switch.nvim"),

      -- 延迟加载配置
      event = "VeryLazy",

      -- 插件配置
      config = function()
        require("im_switch").setup({
          -- 模式-输入法映射
          imname = {
            norm = "keyboard-us",  -- 普通模式：英文键盘
            ins = "rime",         -- 插入模式：Rime
            cmd = "keyboard-us",   -- 命令模式：英文键盘
            vis = "keyboard-us",   -- 可视模式：英文键盘
          },

          -- 记忆上次状态
          remember_prior = true,

          -- 启用Rime状态记忆（核心功能）
          enable_rime_memory = true,

          -- Rime状态检测方法
          rime_state_method = "auto",  -- auto/dbus/lgi/remote

          -- Rime状态缓存时长（毫秒）
          rime_state_cache_ttl = 5000,

          -- 定义自动命令
          define_autocmd = true,

          -- 自动启动fcitx5
          autostart_fcitx5 = true,

          -- 日志级别：debug/info/warn/error
          log_level = "warn",

          -- 启动消息
          msg = "im_switch.nvim loaded! 🚀",
        })

        -- ==========================================
        -- 可选：设置快捷键
        -- ==========================================
        -- 查看当前Buffer状态
        vim.keymap.set("n", "<Leader>is", function()
          local state_manager = require("im_switch.state_manager")
          local bufnr = vim.api.nvim_get_current_buf()
          local state = state_manager.get_buffer_state(bufnr, "ins")

          if state then
            vim.notify(string.format(
              "Buffer %d Insert模式: IM=%s, Rime=%s",
              bufnr,
              tostring(state.im),
              state.rime_ascii == false and "中文" or "英文"
            ), vim.log.levels.INFO)
          else
            vim.notify(string.format("Buffer %d 无保存状态", bufnr), vim.log.levels.WARN)
          end
        end, { desc = "显示当前Buffer输入法状态" })

        -- 手动触发输入法切换
        vim.keymap.set("n", "<Leader>ir", function()
          require("im_switch").ImSwitchGeneious()
        end, { desc = "手动切换输入法" })

        -- 切换到Rime（中文）
        vim.keymap.set("n", "<Leader>ic", function()
          require("im_switch").ImSwitchSetName("rime")
        end, { desc = "切换到Rime" })

        -- 切换到英文键盘
        vim.keymap.set("n", "<Leader>ie", function()
          require("im_switch").ImSwitchSetName("keyboard-us")
        end, { desc = "切换到英文键盘" })
      end,
    },

    -- ==========================================
    -- 其他插件配置
    -- ==========================================
    {
      "folke/tokyonight.nvim",
      lazy = false,  -- 立即加载（主题）
      priority = 1000,
      config = function()
        require("tokyonight").setup({
          style = "storm",
        })
        vim.cmd.colorscheme("tokyonight")
      end,
    },

    -- ==========================================
    -- 自动更新插件配置
    -- ==========================================
    {
      "folke/lazy.nvim",
      version = "*",
      opts = {
        -- 自动检查更新
        checker = {
          enabled = true,           -- 启用更新检查
          frequency = 3600,         -- 每小时检查一次（秒）
          notify = true,            -- 有更新时通知
        },

        -- 自动安装缺失的插件
        install = {
          missing = true,
          -- 安装后自动编译
          compile = true,
        },

        -- 自动更新
        update = {
          -- 自动更新的模式：nil/none/start/sync
          mode = "sync",            -- 启动时同步更新
          -- 并发数
          concurrency = 5,
          -- 通知行为
          notify = true,
        },

        -- 更改检查器（用于开发）
        change_detection = {
          enabled = true,
          notify = true,
        },

        -- 性能优化
        performance = {
          cache = {
            enabled = true,
          },
          reset_packpath = true,
          rtp = {
            reset = true,
            -- 默认路径
            paths = { "~/.local/share/nvim/site" },
          },
        },

        -- 调试模式（开发时启用）
        debug = false,

        -- 状态栏配置（可选）
        ui = {
          icons = {
            cmd = "⌘",
            config = "🛠",
            event = "📅",
            ft = "📂",
            init = "⚙",
            import = "",
            keys = "🗝",
            lazy = "💤 ",
            loaded = "✅",
            not_loaded = "❌",
            plugin = "🔌",
            runtime = "💻",
            require = "🌙",
            source = "📄",
            start = "🚀",
            task = "📌",
          },
        },
      },
    },
  },

  -- ==========================================
  -- Lazy.nvim 全局配置
  -- ==========================================
  defaults = {
    -- 延迟加载
    lazy = false,
    -- 版本
    version = "*",
    -- 自动安装
    install = true,
  },

  -- ==========================================
  -- 调试配置（开发时使用）
  -- ==========================================
  debug = false,

  -- ==========================================
  -- 性能配置
  -- ==========================================
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true,
    rtp = {
      reset = true,
      paths = { "~/.local/share/nvim/site" },
    },
  },

  -- ==========================================
  -- Lockfile配置
  -- ==========================================
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
})
