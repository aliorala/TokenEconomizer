# Windows kullanıcı kurulumu

Python 3.10+ ve güncel Codex CLI gerekir. Kurulum dosyalarını da içeren fork'u yeni makineye klonlayın (çekirdek Microsoft TokenEconomizer kaynak kodudur):

```powershell
git clone https://github.com/aliorala/TokenEconomizer.git
Set-Location TokenEconomizer
.\Install-TokenEconomizer.ps1 -DryRun
.\Install-TokenEconomizer.ps1
```

Gerekirse `-SourcePath C:\src\TokenEconomizer -PythonPath C:\Python313\python.exe -CodexPath C:\tools\codex.exe` verin. Varsayılan Python araması Codex runtime Python'unu ve PATH'i denetler; Windows Store yönlendirmelerini kabul etmez. Runtime güncellenip yol değişirse kurulumu yeniden çalıştırın. PowerShell yürütme politikasını değiştirmek gerekirse kurumunuzun kurallarını izleyin; betik politika veya izin atlaması yapmaz.

İsterseniz yalnız bu kurulum dosyalarını indirin, yanına `git clone https://github.com/microsoft/TokenEconomizer.git` ile resmi kaynağı klonlayın ve betiğe `-SourcePath .\TokenEconomizer` verin. Betik kendi klasöründe, üst repo kökünde veya kardeş `TokenEconomizer` klasöründe kaynağı otomatik tanır.

Betik upstream `scripts/build_plugin.py` ile `%USERPROFILE%\.codex\tools\tokeneconomizer-marketplace` altında kendi kodunu içeren bundle üretir. `CODEX_HOME` tanımlıysa bu kök kullanılır. Önceki bundle, Codex config.toml, değişen AGENTS.md ve TE config dosyası yanında tarihli yedeklenir. Marketplace kullanıcı Codex CLI'sine kaydedilir; mevcut kurulumda aynı komutları yeniden çalıştırabilirsiniz. Hata olursa sonraki adımlar durur; tamamlanan CLI işlemleri otomatik geri alınmaz. Kaynak klonu güncelledikten sonra bu betiği yeniden çalıştırın.

Global TE ayarları resmi CLI üzerinden `microskills=envfacts`, `toolprune=propose`, `loopguard=on` olur. Ortam bilgileri öğrenilir; önerilen araç listesi kendiliğinden uygulanmaz ve ajanlar kapatılmaz. Microskills proposer için ek model çağrısı yapılmaz. Loopguard'ın varsayılan judge çağrıları ve maliyetleri mümkün olmaya devam eder. Depoya özgü TE ayarları global değerleri geçersiz kılabilir. `TOKENECONOMIZER_HOME` tanımlıysa TE verisi oraya, aksi halde `~/.tokeneconomizer` altına yazılır (`TE_HOME` upstream tarafından kullanılmaz).

Codex'i açın, resmi **Hooks need review** ekranında hookları inceleyip uygun gördüğünüzde **Trust all and continue** seçin. Codex'i kapatıp yeni oturum açın; `$tokeneconomizer:status` ile kontrol edin. Betik hook güveni/hash, sandbox veya approval ayarlarını değiştirmez. Diğer eklentileri ve kullanıcı ajan talimatlarını korur; global AGENTS.md içine tek, kısa marker bloğu ekler.

Terminalden durum:

```powershell
& 'C:\Python313\python.exe' "$env:USERPROFILE\.codex\tools\tokeneconomizer-marketplace\tokeneconomizer\scripts\te_bootstrap.py" cli --host codex status
```

Taşınabilir paket `Install-TokenEconomizer.ps1`, `Test-Install-TokenEconomizer.ps1`, `WINDOWS-KURULUM.md` ve resmi kaynak kodudur. Kullanıcı state/sessions/auth dosyalarını, `.tokeneconomizer` veya `.codex` dizinlerini başka makineye kopyalamayın. Kaynağın lisansı değiştirilmez. `-DryRun` yolları, kaynak yapısını ve Python sürümünü doğrular; hiçbir dosya yazmaz veya kurulum yapmaz. Ağ/CLI uyumluluğunu ve kullanıcı hook onayını kanıtlamaz.

Geliştirici doğrulaması: `Test-Install-TokenEconomizer.ps1`, yalnız betiğin yanında `.test-*` altında geçici kullanıcı kökleri ve sahte Codex CLI kullanır. Gerçek hesap ayarlarını değiştirmez; gerçek Codex eklenti kaydının yerine geçmez.
