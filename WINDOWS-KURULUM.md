# Windows kullanıcı kurulumu

Bu rehber TokenEconomizer içindir. Rues'un 14 ajanıyla birlikte kullanım için [ortak rehbere](https://github.com/aliorala/rues-orkestra/blob/main/KULLANIM.md) bakın; Rues deposu özeldir ve GitHub hesabınızın erişimi gerekir. Diğer Codex eklentilerini kurmaz. Aynı Codex hesabıyla başka PC'ye giriş yapmak yerel kurulumu otomatik taşımaz. Normal web ChatGPT sohbetlerine etkisi yoktur.

## Tek komutla başla

Windows PowerShell 5.1+, Git, güncel Codex CLI/hesabı ve Python 3.10+ gerekir. PowerShell'i kaynak dosyalarını tutacağınız klasörde açın. `TokenEconomizer` klasörü henüz yoksa:

```powershell
& { $ErrorActionPreference = 'Stop'; git clone https://github.com/aliorala/TokenEconomizer.git TokenEconomizer; if ($LASTEXITCODE -ne 0) { throw 'TokenEconomizer indirilemedi' }; powershell -NoProfile -ExecutionPolicy Bypass -File .\TokenEconomizer\Install-TokenEconomizer.ps1; if ($LASTEXITCODE -ne 0) { throw 'TokenEconomizer kurulumu başarısız' } }
```

`-ExecutionPolicy Bypass` yalnız bu PowerShell sürecine aittir; kalıcı politikayı değiştirmez. Kurum cihazında izin verilen yöntemi izleyin. Kurucu Python'u Codex runtime'ından, PATH'ten ve `py.exe` üzerinden algılar; bulunamazsa aşağıdaki `-PythonPath` örneğini kullanın.

Kurulumun ardından Codex'in **Hooks need review** ekranında hookları kullanıcı olarak inceleyip uygun bulursanız **Trust all and continue** seçin. Kurucu bu güven adımını sizin yerinize tamamlamaz. Yeni Codex oturumu açıp `$tokeneconomizer:status` yazın.

## Günlük kullanım

Projenizi Codex'te açıp normal çalışmaya devam edin. Mevcut skill'ler kaynakta `plugin/codex-skills/` altındadır:

| Sohbete yazın | Sonuç |
|---|---|
| `$tokeneconomizer:status` | Depodaki ölçülen durum, oturum maliyeti ve öğrenmeler |
| `$tokeneconomizer:microskills` | Öğrenilen ve oluşmakta olan depo bilgileri |
| `$tokeneconomizer:config` | Ayarları gösterir; değişiklik istediğinizde ayrıca belirtin |
| `$tokeneconomizer:toolprune` | Araç önerilerini gösterir; uygulamak veya geri almak ayrıca açık istek ister |
| `$tokeneconomizer:repos` | İzlenen depoları listeler; state birleştirmek/taşımak ayrıca açık istek ister |

Örneğin “TokenEconomizer ayarlarını göster”, “Bu projede öğrendiğin bilgileri göster” veya “Araç önerilerini göster, uygulama” yazabilirsiniz. `toolprune=propose` araçları otomatik kapatmaz. `microskills=envfacts` ortam bilgilerini yeniden kullanır; microskills proposer için ek model çağrısı yapmaz. `loopguard=on` tekrarlayan başarısızlık döngülerine müdahale eder; varsayılan judge çağrıları maliyet oluşturabilir. Depoya özgü ayarlar global değerlerin önüne geçer. Tasarruf garantisi yoktur; ölçülen raporu izleyin.

## Güncelleme

Depoyu indirdiğiniz üst klasörde:

```powershell
& { $ErrorActionPreference = 'Stop'; git -C .\TokenEconomizer pull --ff-only; if ($LASTEXITCODE -ne 0) { throw 'TokenEconomizer güncellenemedi' }; powershell -NoProfile -ExecutionPolicy Bypass -File .\TokenEconomizer\Install-TokenEconomizer.ps1; if ($LASTEXITCODE -ne 0) { throw 'TokenEconomizer kurulumu başarısız' } }
```

GitHub **Sync fork** yalnız GitHub'daki fork'u kaynakla eşitler; PC'ye kurulum yapmaz. Bu fork'ta kişisel Windows kurucusu ve belgeler vardır; upstream değişiklikleri bunlarla çakışırsa zorla güncelleme yapmayın, karşılaştırıp birleştirin. `pull --ff-only` başarısızsa kurucu çalıştırılmaz. Runtime Python yolu değiştiğinde de kurucuyu yeniden çalıştırın; gerekiyorsa hook inceleme ekranını tekrar tamamlayın.

## Ayrıntılı kurulum ve yedekler

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
