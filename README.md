# hugoBlob 使用与部署说明（面向小白）

这个仓库是博客“源代码仓库”，里面包含：
- 文章内容（content/post，为子模块）
- 站点配置与主题
- 构建后的静态网页（public，为子模块，会发布到 GitHub Pages）

你只需要会复制粘贴命令，就能完成本地预览与部署发布。

## 0. 你需要准备什么
1. 安装 Git（用来拉代码、提交发布）
2. 安装 Hugo extended 版本（用来生成网页）
3. 能访问 GitHub，并且你的电脑已经配置好 GitHub 的 SSH key

说明：
- 本项目子模块使用 `git@github.com:...` 的 SSH 地址；如果你没配 SSH，会出现权限错误。

## 1. 第一次拉取项目（只做一次）

在任意目录打开终端，执行：

```bash
git clone --recurse-submodules git@github.com:omgkill/hugoBlob.git
cd hugoBlob
```

如果你已经 clone 过但子模块没拉全，执行：

```bash
git submodule update --init --recursive
```

## 2. 本地预览（改完就能看效果）

进入项目根目录（有 config.toml 的那个目录），执行：

```bash
hugo server --disableFastRender --renderToDisk
```

然后用浏览器打开：
- http://localhost:1313/

为什么要加这些参数：
- `--disableFastRender`：避免 Hugo 的快速渲染导致生成内容不更新
- `--renderToDisk`：把生成的文件写入 public，方便你检查生成结果

停止预览：在终端按 Ctrl + C

## 3. 写文章 / 改内容

文章在子模块里：
- `content/post/`

你可以直接在 `content/post/` 目录下新增或编辑 markdown 文件（`.md`）。

## 4. 更新内容子模块（wiki 仓库）

如果你只是想同步远端已有文章（拉取最新内容），执行：

```bash
cd content/post
git checkout master
git pull
cd ../..
```

如果你在 `content/post` 里新增/修改了文章，还需要在 `content/post` 里自己提交一次（它是独立仓库）：

```bash
cd content/post
git status
git add .
git commit -m "update posts"
git push
cd ../..
```

## 5. 生成网站（把源内容变成 public 静态网页）

在项目根目录执行：

```bash
hugo --theme=jane --baseURL="https://omgkill.github.io/"
```

这一步会把最新构建结果写到 `public/` 目录。

## 6. 发布到线上（GitHub Pages）

发布的关键点：
- `public/` 是一个子模块，对应仓库 `omgkill/omgkill.github.io`
- 你需要先提交 `public` 子模块，再提交主仓库

### 6.1 提交 public 子模块并推送

```bash
cd public
git checkout master
git status
git add .
git commit -m "update public"
git push
cd ..
```

### 6.2 提交主仓库并推送（记录子模块指针更新）

```bash
git status
git add .
git commit -m "update site"
git push
```

完成后，等待 GitHub Pages 自动更新即可。

## 7. 常见问题

### 7.1 public 没有更新
最常见原因：
- 你运行的是 `hugo server` 但没有写盘参数，所以 public 不变

用这个预览并写盘：

```bash
hugo server --disableFastRender --renderToDisk
```

### 7.2 子模块拉取失败 / 权限错误
最常见原因：
- 没有配置 GitHub SSH key（因为子模块 URL 是 SSH）

解决思路：
- 先确保 `ssh -T git@github.com` 能正常连接（需要你本机已配置 SSH key）

## 8. 目录说明（了解即可）
- `content/post`：文章仓库（子模块）
- `public`：发布仓库（子模块，GitHub Pages）
- `themes/jane`：主题
- `layouts`：自定义模板（例如 index.json/search 页面）
- `static`：静态资源（例如搜索脚本）
