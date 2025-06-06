# 📚 BookNest

**BookNest** es una aplicación móvil desarrollada en Flutter que conecta a amantes de la lectura para intercambiar libros, tanto físicos como digitales. A través de un sistema de geolocalización, permite encontrar lectores cercanos, visualizar bibliotecas y coordinar préstamos seguros. También incluye un sistema de reseñas y valoraciones donde los usuarios pueden dar sus opiniones sobre los libros leídos.
BookNest es una aplicación multiplataforma, compatible con Android, iOS y navegadores web.

---

## 🚀 Funcionalidad

- Geolocalización para encontrar lectores cercanos.  
- Visualización de bibliotecas de otros usuarios.  
- Coordinación de préstamos de libros físicos y digitales.  
- Filtros de búsqueda avanzada.  
- Valoraciones y reseñas de usuarios.  
- Listas de favoritos.  
- Recordatorios para disponibilidad de libros.  
- Gestión de biblioteca personal.  
- Sistema de chat interno.  
- Automatización de tareas mediante funciones programadas.  
- Pruebas unitarias bajo patrón AAA.  
- Arquitectura organizada con MVVM.  
- Manual de usuario y manual técnico incluidos.  

---

## 🛠 Tecnologías utilizadas

- **Flutter** – Desarrollo multiplataforma para iOS, Android y Web.  
- **Supabase** – Autenticación, base de datos y almacenamiento.  
- **Supabase Edge Functions** – Automatización de lógica backend.  
- **Cronjob** – Ejecución periódica de funciones.  
- **Docker Desktop** – Contenedores locales para poder subir las funciones a Supabase.  

---

## 📦 ¿Cómo usarlo?

### 🔽 Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/booknest.git
cd booknest
```

### ▶️ Ejecutar la app
**Android**
```bash
flutter pub get
flutter run
```

**iOS**
```bash
flutter pub get
cd ios
pod install
cd ..
flutter run
```

**Web**
```bash
flutter config --enable-web
flutter run -d chrome
```

## 🧪 Ejecutar pruebas
```bash
flutter test
```