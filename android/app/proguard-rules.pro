# Regles de R8 per a la versió de llançament. El plugin de Flutter afegeix
# aquest fitxer sol (si existeix) a les regles del build type `release`.

# Inici de sessió amb Google (google_sign_in 7 → Credential Manager).
# Credential Manager carrega per reflexió la implementació de Google Play
# Services; R8 no ho veu i l'eliminava, i a l'APK de llançament «Continuar amb
# Google» fallava (en debug funcionava). Regla recomanada per Android:
# https://developer.android.com/identity/sign-in/credential-manager
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** {
  *;
}

# Credencials de Google (ID token) que es converteixen des de les dades rebudes.
-keep class com.google.android.libraries.identity.googleid.** { *; }

# SharedPreferencesAsync: shared_preferences_android 2.5 crida el seu codi
# Kotlin per JNI (paquet `jni`), buscant classes i mètodes pel nom exacte. Les
# funcions `suspend` fan servir aquestes classes de Kotlin, i R8 les reanomenava
# o les eliminava: la crida fallava (NoSuchMethodError, ClassNotFoundException).
# Qui entrava amb Google sense nom d'usuari (l'app llegeix aleshores les
# preferències) es quedava a «Inicia sessió». Les regles de `jni` només
# protegeixen el seu propi codi; aquesta és la llista de classes de Kotlin que
# busca pel nom (jni 1.1.0).
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
