# Quy tắc giữ các class cần thiết

# Giữ các class liên quan đến ZEGO (com.itgsa.opensdk.mediaunit.KaraokeMediaHelper)
-keep class com.itgsa.opensdk.** { *; }
-dontwarn com.itgsa.opensdk.**

# Giữ các class liên quan đến SSL/TLS (org.conscrypt)
-keep class org.conscrypt.** { *; }
-keep class com.android.org.conscrypt.** { *; }
-dontwarn org.conscrypt.**
-dontwarn com.android.org.conscrypt.**

# Giữ các class liên quan đến org.apache.harmony (SSL/TLS cũ)
-keep class org.apache.harmony.xnet.provider.jsse.** { *; }
-dontwarn org.apache.harmony.xnet.provider.jsse.**

# Giữ các class của Jackson (java.beans)
-keep class java.beans.** { *; }
-dontwarn java.beans.**

# Giữ các class liên quan đến DOM (org.w3c.dom)
-keep class org.w3c.dom.** { *; }
-dontwarn org.w3c.dom.**

# Giữ các class của ZEGO nói chung
-keep class **.zego.** { *; }

# Giữ các class của plugin floating
-keep class eu.wroblewscy.marcin.floating.floating.** { *; }

# Ngăn R8 cảnh báo về các class không tìm thấy (từ missing_rules.txt)
-dontwarn com.android.org.conscrypt.SSLParametersImpl
-dontwarn com.itgsa.opensdk.mediaunit.KaraokeMediaHelper
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.apache.harmony.xnet.provider.jsse.SSLParametersImpl
-dontwarn org.w3c.dom.html.HTMLDocument
-dontwarn org.w3c.dom.views.AbstractView

# Ngăn R8 cảnh báo về các class không tìm thấy (quy tắc tổng quát)
-dontwarn **