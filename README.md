# mcg-linux-fix

将 `MinecraftGensoukyo1.12.2（密码mcg）.zip` 转换为修复后的 Prism Launcher 导入包 `MCG-Prime.zip`。

## 使用

从 QQ 群获取整合包，然后加入 Nix store：

```sh
nix store add --mode flat --hash-algo sha256 --name mcg-source.zip "/path/to/MinecraftGensoukyo1.12.2（密码mcg）.zip"
```

然后构建：

```sh
nix build github:Eason20000/mcg-linux-fix
```

随后在 Prism Launcher 中导入 `result/MCG-Prime.zip` 即可。

## 资料来源

[Linux 游玩 MineCraft幻想乡 1.12.2 的指南 - MCG大图书馆](https://wiki.gensoukyo.moe/wiki/Linux_%E6%B8%B8%E7%8E%A9_MineCraft%E5%B9%BB%E6%83%B3%E4%B9%A1_1.12.2_%E7%9A%84%E6%8C%87%E5%8D%97)
