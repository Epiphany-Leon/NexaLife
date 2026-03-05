## 在 Xcode 中注册 URL Scheme

1. 选中项目 → 选中 Target `LifeOS`
2. 点击 `Info` 标签页
3. 展开 `URL Types`，点击 `+`
4. 填写：
   - **Identifier**: `com.lihonggao.LifeOS`
   - **URL Schemes**: `lifeos`
   - **Role**: `Editor`

这样 `lifeos://apple-auth`、`lifeos://google-auth` 回调才能被 App 接收。
