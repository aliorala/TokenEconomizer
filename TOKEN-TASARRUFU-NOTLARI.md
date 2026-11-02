# TokenEconomizer değerlendirmesi — 2 Kasım 2026

Kaynak: https://github.com/microsoft/TokenEconomizer

Makale: https://arxiv.org/html/2610.22732v1

## İddianın sınırı

Yazarların 277 SWE-Bench görevi, altı depo ve beş ajan/model birleşimindeki deneyleri %18,4–30,9 ortalama maliyet düşüşü bildiriyor. Codex + GPT-5.6 Terra için %24,7, GPT-5.6 Sol için %26,1. Bu, ham token sayısındaki düşüşle veya abonelik kotasının aynı oranda uzamasıyla eş anlamlı değil. Hesap önbellek fiyatlarını ve eklentinin ek model çağrılarını içeriyor.

Başarı beş birleşimin dördünde artarken Opus 4.8'de 1 yüzde puanı düşmüş. Bağımsız tekrar deneyini doğrulamadık. GPT-6/6.1, Türkçe genel sohbetler ve bu kişisel orkestra düzeni için aynı oran kanıtlanmış değil.

Güncel eklenti varsayılanları makaledeki deneyle aynı değil: bilgi öneren model varsayılan olarak kapalı, döngü denetimi kendi başına turu durdurmuyor. Dolayısıyla bu kuruluma deney yüzdeleri vaat edilmez.

## Seçilen kullanıcı ayarları

- `microskills=envfacts`: tekrar eden ortam sorunlarından model çağrısı yapmadan öğrenir.
- `toolprune=propose`: kullanılmayan araçları kapatmayı önerir; otomatik kapatmaz. Çok ajan kullanma tercihini korur.
- `loopguard=on` (saklanan değer `nudge`): döngü belirtilerinde yönlendirme yapabilir; hakem model çağrısı kotaya ek maliyet getirebilir.

Bu tercihler deneydeki maksimum tasarruf ayarı değildir. Gerçek kazanç, benzer görevlerin toplam tüketimi ve başarı kalitesi birlikte izlenerek anlaşılır. Durum raporu tek başına karşı olgusal tasarruf kanıtı değildir.

## Kapsam ve yeniden kurulum

`Install-TokenEconomizer.ps1` Codex kullanıcı dizinine kurar. Yerel projelerde yeni oturumlar eklentiyi yükleyebilir; proje ayarları global ayarları geçersiz kılabilir. Hooklar Codex'in resmi inceleme ekranında onaylanmalı ve ardından yeni oturum açılmalı. Mevcut açık sohbetlere anında geriye dönük uygulama garanti edilmez.

Normal ChatGPT web sohbetleri, bulut ortamları ve diğer bilgisayarlar bu yerel eklentiyi otomatik almaz. Yeni bilgisayarda bu depoyu klonlayıp kurulum betiğini çalıştırın. Kişisel oturumlar, kimlik bilgileri ve öğrenilmiş proje verileri bu depoya yüklenmez.

Global talimatların kapsamı: https://learn.chatgpt.com/docs/agent-configuration/agents-md

Kurulum ve güncel davranış: https://github.com/microsoft/TokenEconomizer/blob/main/plugin/README.md
