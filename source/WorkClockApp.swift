// Tally, created by Gil Nobre.
import SwiftUI
import Charts
import Combine
import LocalAuthentication
import AppKit
import Carbon.HIToolbox
import ServiceManagement
import UniformTypeIdentifiers

// MARK: - Colours

extension NSColor {
    convenience init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                  green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Color {
    init(hex: String) { self.init(nsColor: NSColor(hex: hex)) }
}

func isValidHex(_ s: String) -> Bool {
    let h = s.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
    return h.count == 6 && h.allSatisfy { $0.isHexDigit }
}

func normalizedHex(_ s: String) -> String {
    s.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
}

func perceivedBrightness(_ hex: String) -> Double {
    let c = NSColor(hex: hex)
    return Double(0.299 * c.redComponent + 0.587 * c.greenComponent + 0.114 * c.blueComponent)
}

// MARK: - Languages

enum AppLang: String, CaseIterable, Identifiable {
    case en, pt, es
    var id: String { rawValue }

    /// Portuguese means European Portuguese.
    var label: String {
        switch self {
        case .en: return "English"
        case .pt: return "Português"
        case .es: return "Español"
        }
    }

    var locale: Locale {
        switch self {
        case .en: return Locale(identifier: "en")
        case .pt: return Locale(identifier: "pt_PT")
        case .es: return Locale(identifier: "es")
        }
    }

    /// The Mac's own language, used until you pick one.
    static var system: AppLang {
        let first = (Locale.preferredLanguages.first ?? "en").lowercased()
        if first.hasPrefix("pt") { return .pt }
        if first.hasPrefix("es") { return .es }
        return .en
    }
}

enum Loc {
    static var current: AppLang = {
        if let raw = UserDefaults.standard.string(forKey: "language"), let l = AppLang(rawValue: raw) { return l }
        return AppLang.system
    }()
}

/// Translates an English interface text. Use %@ for values.
func T(_ key: String, _ args: CVarArg...) -> String {
    var s = key
    if Loc.current != .en, let row = translations[key] {
        s = Loc.current == .pt ? row.pt : row.es
    }
    return args.isEmpty ? s : String(format: s, arguments: args)
}

private let translations: [String: (pt: String, es: String)] = [
    // Messages
    "Your log file could not be read. A copy was kept in the data folder.":
        (pt: "Não foi possível ler o ficheiro do registo. Foi guardada uma cópia na pasta de dados.",
         es: "No se pudo leer el archivo del registro. Se guardó una copia en la carpeta de datos."),
    "Your last session was closed at %@ because the app restarted. You can edit it in the Log.":
        (pt: "A tua última sessão foi fechada às %@ porque a app reiniciou. Podes editá-la no Registo.",
         es: "Tu última sesión se cerró a las %@ porque la app se reinició. Puedes editarla en el Registro."),
    "Stopped %@ at %@ when your Mac went to sleep.":
        (pt: "%@ parou às %@ quando o Mac entrou em repouso.",
         es: "%@ se detuvo a las %@ cuando tu Mac entró en reposo."),
    "Could not change the open at login setting: %@":
        (pt: "Não foi possível alterar o arranque ao iniciar sessão: %@",
         es: "No se pudo cambiar el inicio al abrir sesión: %@"),
    "Open Tally": (pt: "Abrir o Tally", es: "Abrir Tally"),
    "Clock out of %@": (pt: "Parar o relógio de %@", es: "Parar el reloj de %@"),
    "Clock in": (pt: "Iniciar", es: "Iniciar"),
    "Clock in to %@": (pt: "Iniciar o relógio de %@", es: "Iniciar el reloj de %@"),
    "Give the project a name.": (pt: "Dá um nome ao projeto.", es: "Ponle un nombre al proyecto."),
    "You already have a project called %@.": (pt: "Já tens um projeto chamado %@.", es: "Ya tienes un proyecto llamado %@."),
    "That is the limit: 12 projects.": (pt: "Esse é o limite: 12 projetos.", es: "Ese es el límite: 12 proyectos."),
    "The key %@ is already used by %@.": (pt: "A tecla %@ já é usada por %@.", es: "La tecla %@ ya la usa %@."),
    "Control+W is reserved for choosing a project. Pick another key.":
        (pt: "Control+W está reservado para escolher um projeto. Escolhe outra tecla.",
         es: "Control+W está reservado para elegir un proyecto. Elige otra tecla."),
    "That key cannot be used as a shortcut.": (pt: "Essa tecla não pode ser usada como atalho.", es: "Esa tecla no se puede usar como atajo."),

    // Home
    "Project name": (pt: "Nome do projeto", es: "Nombre del proyecto"),
    "%@ today": (pt: "%@ hoje", es: "%@ hoy"),
    "What are you starting?": (pt: "O que vais começar?", es: "¿Qué vas a empezar?"),
    "Press a key to start. Esc to cancel.": (pt: "Prime uma tecla para começar. Esc para cancelar.", es: "Pulsa una tecla para empezar. Esc para cancelar."),
    "Track": (pt: "Tempo", es: "Tiempo"),
    "Stats": (pt: "Estatísticas", es: "Estadísticas"),
    "Log": (pt: "Registo", es: "Registro"),
    "Projects": (pt: "Projetos", es: "Proyectos"),
    "Quit Tally": (pt: "Sair do Tally", es: "Salir de Tally"),
    "TRACKING %@": (pt: "A REGISTAR %@", es: "REGISTRANDO %@"),
    "since %@": (pt: "desde as %@", es: "desde las %@"),
    "READY": (pt: "PRONTO", es: "LISTO"),
    "Add a project to start": (pt: "Adiciona um projeto para começar", es: "Añade un proyecto para empezar"),
    "Pick a project to start": (pt: "Escolhe um projeto para começar", es: "Elige un proyecto para empezar"),
    "Add your first project": (pt: "Adiciona o teu primeiro projeto", es: "Añade tu primer proyecto"),
    "Clock out": (pt: "Parar", es: "Parar"),
    "Switch": (pt: "Mudar", es: "Cambiar"),
    "choose": (pt: "escolher", es: "elegir"),
    "New project": (pt: "Novo projeto", es: "Nuevo proyecto"),

    // Stats
    "Today": (pt: "Hoje", es: "Hoy"),
    "This week": (pt: "Esta semana", es: "Esta semana"),
    "This month": (pt: "Este mês", es: "Este mes"),
    "This year": (pt: "Este ano", es: "Este año"),
    "All": (pt: "Tudo", es: "Todo"),
    "Last 7 days": (pt: "Últimos 7 dias", es: "Últimos 7 días"),
    "Averages": (pt: "Médias", es: "Promedios"),
    "Per day": (pt: "Por dia", es: "Por día"),
    "Per week": (pt: "Por semana", es: "Por semana"),
    "Per month": (pt: "Por mês", es: "Por mes"),
    "Per day only counts days you worked. Weeks and months count from your first log.":
        (pt: "Por dia conta só os dias em que trabalhaste. Semanas e meses contam desde o teu primeiro registo.",
         es: "Por día cuenta solo los días que trabajaste. Semanas y meses cuentan desde tu primer registro."),

    // Log and editing
    "Nothing logged yet.": (pt: "Ainda nada registado.", es: "Todavía no hay nada registrado."),
    "Add time": (pt: "Adicionar tempo", es: "Añadir tiempo"),
    "Edit time": (pt: "Editar tempo", es: "Editar tiempo"),
    "Export CSV": (pt: "Exportar CSV", es: "Exportar CSV"),
    "%@ to %@": (pt: "%@ até %@", es: "%@ a %@"),
    "now": (pt: "agora", es: "ahora"),
    "Start": (pt: "Início", es: "Inicio"),
    "End": (pt: "Fim", es: "Fin"),
    "Still running. Clock out to set the end time.":
        (pt: "Ainda a decorrer. Pára para definir a hora de fim.", es: "Aún en marcha. Detén el reloj para fijar la hora de fin."),
    "Total: %@": (pt: "Total: %@", es: "Total: %@"),
    "End must be after start.": (pt: "O fim tem de ser depois do início.", es: "El fin debe ser posterior al inicio."),
    "Note (optional)": (pt: "Nota (opcional)", es: "Nota (opcional)"),
    "Delete": (pt: "Apagar", es: "Eliminar"),
    "Cancel": (pt: "Cancelar", es: "Cancelar"),
    "Save": (pt: "Guardar", es: "Guardar"),

    // Projects tab and settings
    "No projects yet. Add one to start tracking.":
        (pt: "Ainda não há projetos. Adiciona um para começar.", es: "Aún no hay proyectos. Añade uno para empezar."),
    "Archived": (pt: "Arquivados", es: "Archivados"),
    "Restore": (pt: "Restaurar", es: "Restaurar"),
    "Hours of archived projects stay in your Log and Stats.":
        (pt: "As horas dos projetos arquivados ficam no Registo e nas Estatísticas.",
         es: "Las horas de los proyectos archivados se quedan en el Registro y las Estadísticas."),
    "Settings": (pt: "Definições", es: "Ajustes"),
    "Use Touch ID": (pt: "Usar Touch ID", es: "Usar Touch ID"),
    "Off: no fingerprint is asked. Use this if your Mac has no Touch ID.":
        (pt: "Desligado: não é pedida a impressão digital. Usa isto se o teu Mac não tem Touch ID.",
         es: "Desactivado: no se pide la huella. Úsalo si tu Mac no tiene Touch ID."),
    "Language": (pt: "Idioma", es: "Idioma"),
    "Shortcuts": (pt: "Atalhos", es: "Atajos"),
    "Made by Gil Nobre": (pt: "Feito por Gil Nobre", es: "Hecho por Gil Nobre"),
    "Feedback or feature suggestions:": (pt: "Feedback ou sugestões:", es: "Comentarios o sugerencias:"),
    "Clock out, or choose what to start": (pt: "Parar, ou escolher o que começar", es: "Parar, o elegir qué empezar"),
    "Show quick instructions": (pt: "Ver instruções rápidas", es: "Ver instrucciones rápidas"),
    "Open at login": (pt: "Abrir ao iniciar sessão", es: "Abrir al iniciar sesión"),
    "To turn this on, put Tally in your Applications folder and open it from there.":
        (pt: "Para ativar, coloca o Tally na pasta Aplicações e abre-o a partir daí.",
         es: "Para activarlo, mueve Tally a la carpeta Aplicaciones y ábrelo desde allí."),
    "macOS needs your OK in System Settings > General > Login Items.":
        (pt: "O macOS precisa da tua autorização em Definições do Sistema > Geral > Itens de início.",
         es: "macOS necesita tu permiso en Ajustes del Sistema > General > Ítems de inicio."),

    // Project window
    "Edit project": (pt: "Editar projeto", es: "Editar proyecto"),
    "Name": (pt: "Nome", es: "Nombre"),
    "For example: Writing, Client work, Gym":
        (pt: "Por exemplo: Escrita, Clientes, Ginásio", es: "Por ejemplo: Escritura, Clientes, Gimnasio"),
    "Colour": (pt: "Cor", es: "Color"),
    "Or a custom colour": (pt: "Ou uma cor à escolha", es: "O un color personalizado"),
    "Logo or photo (optional)": (pt: "Logótipo ou foto (opcional)", es: "Logo o foto (opcional)"),
    "Choose image…": (pt: "Escolher imagem…", es: "Elegir imagen…"),
    "Remove": (pt: "Remover", es: "Quitar"),
    "It shows on the card. Wide logos and square photos both work.":
        (pt: "Aparece no cartão. Logótipos largos e fotos quadradas funcionam.",
         es: "Aparece en la tarjeta. Funcionan logos anchos y fotos cuadradas."),
    "Shortcut": (pt: "Atalho", es: "Atajo"),
    "Starts and stops this project from anywhere. Control + W is always \"choose\".":
        (pt: "Inicia e pára este projeto em qualquer lugar. Control + W serve sempre para escolher.",
         es: "Inicia y detiene este proyecto desde cualquier sitio. Control + W siempre sirve para elegir."),
    "Delete this project…": (pt: "Apagar este projeto…", es: "Eliminar este proyecto…"),
    "%@ is logged on this project. It stays in your Log and Stats, and the project moves to Archived, where you can restore it any time.":
        (pt: "%@ registadas neste projeto. Ficam no Registo e nas Estatísticas, e o projeto passa para Arquivados, onde o podes restaurar quando quiseres.",
         es: "%@ registradas en este proyecto. Se quedan en el Registro y las Estadísticas, y el proyecto pasa a Archivados, donde puedes restaurarlo cuando quieras."),
    "Nothing is logged on this project, so it will be removed.":
        (pt: "Nada registado neste projeto, por isso será removido.", es: "No hay nada registrado en este proyecto, así que se eliminará."),
    "This project is running. Clock out first.":
        (pt: "Este projeto está a decorrer. Pára primeiro.", es: "Este proyecto está en marcha. Deténlo primero."),
    "Type \"%@\" to confirm": (pt: "Escreve \"%@\" para confirmar", es: "Escribe \"%@\" para confirmar"),
    "Keep project": (pt: "Manter projeto", es: "Conservar proyecto"),
    "Delete project": (pt: "Apagar projeto", es: "Eliminar proyecto"),

    // Welcome window and guided tour
    "Welcome to Tally": (pt: "Bem-vindo ao Tally", es: "Bienvenido a Tally"),
    "Click this icon in your menu bar": (pt: "Clica neste ícone na barra de menus", es: "Haz clic en este icono de la barra de menús"),
    "This is where Tally lives. Choose your language, then start the quick instructions.":
        (pt: "É aqui que vive o Tally. Escolhe o idioma e começa as instruções rápidas.",
         es: "Aquí vive Tally. Elige tu idioma y empieza las instrucciones rápidas."),
    "Start quick instructions": (pt: "Começar instruções rápidas", es: "Empezar instrucciones rápidas"),
    "Add a project": (pt: "Adiciona um projeto", es: "Añade un proyecto"),
    "This is where you add and edit projects. We will create one together at the end.":
        (pt: "É aqui que adicionas e editas projetos. No fim, criamos um juntos.",
         es: "Aquí añades y editas proyectos. Al final crearemos uno juntos."),
    "Tally opens at login. Press Control + W any time to start. Want to practise? We can create a project together, step by step.":
        (pt: "O Tally abre ao iniciar sessão. Prime Control + W a qualquer momento para começar. Queres praticar? Podemos criar um projeto juntos, passo a passo.",
         es: "Tally se abre al iniciar sesión. Pulsa Control + W en cualquier momento para empezar. ¿Quieres practicar? Podemos crear un proyecto juntos, paso a paso."),
    "Let's make your first one together, step by step.":
        (pt: "Vamos criar o primeiro juntos, passo a passo.", es: "Vamos a crear el primero juntos, paso a paso."),
    "Create a project": (pt: "Criar um projeto", es: "Crear un proyecto"),
    "Name it": (pt: "Dá-lhe um nome", es: "Ponle nombre"),
    "Type a name for your project, for example Writing or Client work. Then tap Next.":
        (pt: "Escreve um nome para o projeto, por exemplo Escrita ou Clientes. Depois toca em Seguinte.",
         es: "Escribe un nombre para el proyecto, por ejemplo Escritura o Clientes. Luego pulsa Siguiente."),
    "Pick a colour": (pt: "Escolhe uma cor", es: "Elige un color"),
    "Choose a colour for the card. The preview at the top changes as you go.":
        (pt: "Escolhe uma cor para o cartão. A pré-visualização no topo muda à medida que escolhes.",
         es: "Elige un color para la tarjeta. La vista previa de arriba cambia a medida que eliges."),
    "Add a logo or photo": (pt: "Adiciona um logótipo ou foto", es: "Añade un logo o foto"),
    "Optional. Tap Choose image to use a logo or a photo, or just tap Next to skip.":
        (pt: "Opcional. Toca em Escolher imagem para usar um logótipo ou foto, ou toca em Seguinte para saltar.",
         es: "Opcional. Pulsa Elegir imagen para usar un logo o una foto, o pulsa Siguiente para omitir."),
    "Your shortcut": (pt: "O teu atalho", es: "Tu atajo"),
    "This key is suggested from the name. Press Control + this key anywhere to clock in or out. You can change it.":
        (pt: "Esta tecla é sugerida a partir do nome. Prime Control + esta tecla em qualquer lugar para iniciar ou parar. Podes mudá-la.",
         es: "Esta tecla se sugiere a partir del nombre. Pulsa Control + esta tecla desde cualquier sitio para iniciar o parar. Puedes cambiarla."),
    "Save it": (pt: "Guarda", es: "Guárdalo"),
    "Tap Save. Your project appears on the Track tab, ready to use.":
        (pt: "Toca em Guardar. O projeto aparece no separador Tempo, pronto a usar.",
         es: "Pulsa Guardar. El proyecto aparece en la pestaña Tiempo, listo para usar."),
    "Got it": (pt: "Entendi", es: "Entendido"),
    "Your settings": (pt: "As tuas definições", es: "Tus ajustes"),
    "Turn Touch ID on or off, change the language and choose if Tally opens at login.":
        (pt: "Liga ou desliga o Touch ID, muda o idioma e escolhe se o Tally abre ao iniciar sessão.",
         es: "Activa o desactiva Touch ID, cambia el idioma y elige si Tally se abre al iniciar sesión."),
    "Clock in and out": (pt: "Iniciar e parar", es: "Iniciar y parar"),
    "Tap a project to clock in. Tap it again to clock out. Or press Control + its key from anywhere. Control + W lets you choose.":
        (pt: "Toca num projeto para iniciar. Toca outra vez para parar. Ou prime Control + a sua tecla, em qualquer lugar. Control + W deixa-te escolher.",
         es: "Pulsa un proyecto para iniciar. Púlsalo otra vez para parar. O pulsa Control + su tecla, desde cualquier sitio. Control + W te deja elegir."),
    "See your hours": (pt: "Vê as tuas horas", es: "Mira tus horas"),
    "Stats shows totals and averages for each project.":
        (pt: "As Estatísticas mostram totais e médias de cada projeto.", es: "Estadísticas muestra totales y promedios de cada proyecto."),
    "Fix your log": (pt: "Corrige o registo", es: "Corrige tu registro"),
    "Log lets you edit or add time by hand. Going to sleep stops the clock for you.":
        (pt: "O Registo deixa-te editar ou adicionar tempo à mão. Quando o Mac adormece, o relógio pára.",
         es: "El Registro te deja editar o añadir tiempo a mano. Si el Mac se duerme, el reloj se detiene."),
    "You're all set": (pt: "Está tudo pronto", es: "Todo listo"),
    "Create your first project": (pt: "Cria o teu primeiro projeto", es: "Crea tu primer proyecto"),
    "Create first project": (pt: "Criar o primeiro projeto", es: "Crear el primer proyecto"),
    "Skip": (pt: "Saltar", es: "Omitir"),
    "Back": (pt: "Voltar", es: "Atrás"),
    "Next": (pt: "Seguinte", es: "Siguiente"),
    "Done": (pt: "Concluir", es: "Listo")
]

// MARK: - Model

/// One thing you track time for. SMA and Thesis in the personal edition are just two of these.
struct ProjectDef: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var cardHex: String            // background of the card
    var accentHex: String? = nil   // colour of the Clock in button (nil = follows the card)
    var tintHex: String? = nil     // colour in charts and the menu bar (nil = follows the card)
    var key: String = ""           // key in the "what are you starting?" window
    var globalShortcut: Bool = false   // also Control + key from anywhere
    var imagePNG: Data? = nil      // logo or photo
    var archived: Bool = false

    var card: Color { Color(hex: cardHex) }
    var isLightCard: Bool { perceivedBrightness(cardHex) > 0.62 }
    var onCard: Color { isLightCard ? Color.black : Color.white }

    var accent: Color {
        if let a = accentHex { return Color(hex: a) }
        return onCard
    }

    var onAccent: Color {
        if let a = accentHex { return perceivedBrightness(a) > 0.62 ? Color.black : Color.white }
        return card
    }

    /// Colour used in charts and the menu bar. Very dark cards get a lighter tint so they stay visible.
    var tint: Color {
        if let t = tintHex { return Color(hex: t) }
        if perceivedBrightness(cardHex) < 0.35 {
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            NSColor(hex: cardHex).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            if s < 0.12 { return Color(white: 0.75) }
            return Color(hue: Double(h), saturation: Double(min(s, 0.75)), brightness: 0.95)
        }
        return card
    }

    func caption(hours: String) -> String {
        imagePNG == nil ? T("%@ today", hours) : "\(name) · " + T("%@ today", hours)
    }

    /// Used when logged hours point at a project that no longer exists. Keeps the hours visible.
    static func placeholder(id: String) -> ProjectDef {
        ProjectDef(id: id, name: id, cardHex: "52525B", archived: true)
    }
}

struct Session: Codable, Identifiable {
    var id = UUID()
    var project: String      // the id of a ProjectDef. Older files hold "SMA" or "Thesis", which still match.
    var start: Date
    var end: Date?
    var note: String?

    func duration(at now: Date = Date()) -> TimeInterval {
        (end ?? now).timeIntervalSince(start)
    }
}

// MARK: - Helpers

func hm(_ t: TimeInterval) -> String {
    let m = Int((t / 60).rounded())
    return m < 60 ? "\(m)m" : String(format: "%dh %02dm", m / 60, m % 60)
}

func clock(_ t: TimeInterval, seconds: Bool = false) -> String {
    let s = max(0, Int(t))
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return seconds ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", h, m)
}

func shortTime(_ d: Date) -> String {
    d.formatted(date: .omitted, time: .shortened)
}

/// Shrinks a picked image to at most 256 px and returns PNG data.
func pngData(from image: NSImage, maxSide: CGFloat = 256) -> Data? {
    let size = image.size
    guard size.width > 0, size.height > 0 else { return nil }
    let scale = min(1, maxSide / max(size.width, size.height))
    let target = NSSize(width: max(1, (size.width * scale).rounded()), height: max(1, (size.height * scale).rounded()))
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: Int(target.width), pixelsHigh: Int(target.height),
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
    rep.size = target
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(origin: .zero, size: target), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

@MainActor
enum ImageCache {
    private static var cache: [String: NSImage] = [:]
    static func image(for p: ProjectDef) -> NSImage? {
        guard let d = p.imagePNG else { return nil }
        let key = "\(p.id)-\(d.count)-\(d.hashValue)"
        if let img = cache[key] { return img }
        guard let img = NSImage(data: d) else { return nil }
        cache[key] = img
        return img
    }
}

/// Keys that can be used as Control + key shortcuts.
let keyCodes: [String: Int] = [
    "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D, "e": kVK_ANSI_E,
    "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H, "i": kVK_ANSI_I, "j": kVK_ANSI_J,
    "k": kVK_ANSI_K, "l": kVK_ANSI_L, "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O,
    "p": kVK_ANSI_P, "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
    "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X, "y": kVK_ANSI_Y,
    "z": kVK_ANSI_Z,
    "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3, "4": kVK_ANSI_4,
    "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7, "8": kVK_ANSI_8, "9": kVK_ANSI_9
]

// MARK: - Store

@MainActor
final class Store: ObservableObject {
    @Published var projects: [ProjectDef] = []
    @Published var sessions: [Session] = []
    @Published var now = Date()
    @Published var note: String?
    @Published var language: AppLang = Loc.current {
        didSet {
            Loc.current = language
            UserDefaults.standard.set(language.rawValue, forKey: "language")
        }
    }
    /// Which step of the guided tour is showing (nil = no tour).
    @Published var tourStep: Int? = nil
    /// Which step of the guided "create a project" walkthrough is showing (nil = none).
    @Published var guideStep: Int? = nil
    @Published var useTouchID: Bool = UserDefaults.standard.object(forKey: "useTouchID") as? Bool ?? true {
        didSet { UserDefaults.standard.set(useTouchID, forKey: "useTouchID") }
    }

    /// Called after a successful fingerprint when nothing is running, so the app can ask what to start.
    var onNeedChoice: (@MainActor () -> Void)?
    /// Called when a project should be created (nil) or edited.
    var onEditProject: (@MainActor (ProjectDef?) -> Void)?
    /// Opens the new-project window with the step-by-step guide on.
    func startProjectGuide() {
        guideStep = 0
        onEditProject?(nil)
    }

    /// Called to show the quick instructions again.
    var onShowTour: (@MainActor () -> Void)?

    private var timer: Timer?
    private var beat = 0
    private var lastAuth: Date?
    private let dir: URL
    private var sessionsURL: URL { dir.appendingPathComponent("sessions.json") }
    private var projectsURL: URL { dir.appendingPathComponent("projects.json") }

    init() {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WorkClock", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        dir = base

        let fm = FileManager.default
        let hadSessions = fm.fileExists(atPath: sessionsURL.path)
        let hadProjects = fm.fileExists(atPath: projectsURL.path)

        loadSessions()
        loadProjects()

        if !hadProjects {
            if hadSessions {
                // First start of the version with projects: keep an untouched copy of your hours.
                let keep = dir.appendingPathComponent("sessions.before-projects.json")
                if !fm.fileExists(atPath: keep.path) {
                    try? fm.copyItem(at: sessionsURL, to: keep)
                }
            }
            projects = personalProjectSeeds()
        }

        if !hadSessions && !hadProjects && !UserDefaults.standard.bool(forKey: "baselineSeeded") {
            let seeds = personalFirstRunSessions()
            if !seeds.isEmpty { sessions.append(contentsOf: seeds) }
            UserDefaults.standard.set(true, forKey: "baselineSeeded")
        }

        // Hours must never disappear. If any hours point at an unknown project, show it as archived.
        let known = Set(projects.map(\.id))
        for id in Set(sessions.map(\.project)).sorted() where !known.contains(id) {
            projects.append(ProjectDef.placeholder(id: id))
        }

        saveProjects()
        if !sessions.isEmpty || hadSessions { save() }
        closeOrphanSession()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }

        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.stopForSleep() }
        }
        nc.addObserver(forName: NSWorkspace.willPowerOffNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.stopForSleep() }
        }
    }

    var active: Session? { sessions.last(where: { $0.end == nil }) }
    var activeProjects: [ProjectDef] { projects.filter { !$0.archived } }
    var archivedProjects: [ProjectDef] { projects.filter { $0.archived } }

    func def(_ id: String) -> ProjectDef? { projects.first { $0.id == id } }
    func name(_ id: String) -> String { def(id)?.name ?? id }
    func tint(_ id: String) -> Color { def(id)?.tint ?? Color.gray }
    func hasHistory(_ id: String) -> Bool { sessions.contains { $0.project == id } }
    func hoursLogged(_ id: String) -> TimeInterval {
        sessions.filter { $0.project == id }.reduce(0) { $0 + $1.duration(at: now) }
    }

    private func tick() {
        now = Date()
        beat += 1
        if beat % 20 == 0, active != nil {
            UserDefaults.standard.set(now, forKey: "lastSeen")
        }
    }

    // Persistence

    private func loadSessions() {
        guard let data = try? Data(contentsOf: sessionsURL) else { return }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        if let list = try? dec.decode([Session].self, from: data) {
            sessions = list
            if !list.isEmpty {
                // Rolling backup of the last file that loaded fine.
                let backup = dir.appendingPathComponent("sessions.backup.json")
                try? FileManager.default.removeItem(at: backup)
                try? FileManager.default.copyItem(at: sessionsURL, to: backup)
            }
        } else {
            // The file exists but could not be read. Keep a copy so nothing is ever lost.
            let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            try? FileManager.default.copyItem(at: sessionsURL,
                                              to: dir.appendingPathComponent("sessions.unreadable-\(stamp).json"))
            note = T("Your log file could not be read. A copy was kept in the data folder.")
        }
    }

    private func loadProjects() {
        guard let data = try? Data(contentsOf: projectsURL) else { return }
        if let list = try? JSONDecoder().decode([ProjectDef].self, from: data) {
            projects = list
        } else {
            let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            try? FileManager.default.copyItem(at: projectsURL,
                                              to: dir.appendingPathComponent("projects.unreadable-\(stamp).json"))
        }
    }

    private func save() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(sessions) {
            try? data.write(to: sessionsURL, options: .atomic)
        }
    }

    private func saveProjects() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(projects) {
            try? data.write(to: projectsURL, options: .atomic)
        }
    }

    // Safety nets

    /// If the app was closed or crashed while clocked in, end the session at the last time we saw it alive.
    private func closeOrphanSession() {
        guard let i = sessions.lastIndex(where: { $0.end == nil }) else { return }
        let seen = UserDefaults.standard.object(forKey: "lastSeen") as? Date ?? sessions[i].start
        let end = max(seen, sessions[i].start)
        sessions[i].end = end
        note = T("Your last session was closed at %@ because the app restarted. You can edit it in the Log.", shortTime(end))
        save()
    }

    /// Auto stop when the Mac goes to sleep or shuts down.
    private func stopForSleep() {
        guard let i = sessions.lastIndex(where: { $0.end == nil }) else { return }
        let t = Date()
        sessions[i].end = t
        note = T("Stopped %@ at %@ when your Mac went to sleep.", name(sessions[i].project), shortTime(t))
        save()
    }

    // Open at login

    /// Login start only works reliably from the Applications folder.
    var runsFromApplications: Bool {
        let path = Bundle.main.bundlePath
        return path.hasPrefix("/Applications/") || path.hasPrefix(NSHomeDirectory() + "/Applications/")
    }

    var launchAtLoginEnabled: Bool { SMAppService.mainApp.status == .enabled }
    var launchAtLoginNeedsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            note = T("Could not change the open at login setting: %@", error.localizedDescription)
        }
        objectWillChange.send()
    }

    // Touch ID (falls back to Apple Watch or password if needed)

    private func authenticate(reason: String, graceOK: Bool = false) async -> Bool {
        guard useTouchID else { return true }   // switched off in Settings
        if graceOK, let t = lastAuth, Date().timeIntervalSince(t) < 45 { return true }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else { return true }
        do {
            let ok = try await ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if ok { lastAuth = Date() }
            return ok
        } catch {
            return false
        }
    }

    /// Fingerprint first, then the window opens. Start and Stop inside it will not ask again for 45 seconds.
    func unlock() async -> Bool {
        await authenticate(reason: T("Open Tally"))
    }

    // Clocking in and out

    func stop() {
        note = nil
        if let i = sessions.lastIndex(where: { $0.end == nil }) {
            sessions[i].end = Date()
        }
        save()
    }

    func start(_ id: String) {
        guard let p = def(id), !p.archived else { return }
        note = nil
        let t = Date()
        if let i = sessions.lastIndex(where: { $0.end == nil }) {
            sessions[i].end = t
        }
        sessions.append(Session(project: p.id, start: t))
        UserDefaults.standard.set(t, forKey: "lastSeen")
        save()
    }

    /// The one-key flow. Fingerprint, then:
    /// running -> clock out. Not running -> ask what to start.
    func primaryAction() async {
        if let a = active {
            guard await authenticate(reason: T("Clock out of %@", name(a.project))) else { return }
            stop()
        } else {
            guard await authenticate(reason: T("Clock in")) else { return }
            onNeedChoice?()
        }
    }

    /// Tap the running project to clock out, another one to switch, any one while idle to clock in.
    func tap(_ id: String, graceOK: Bool = false) async {
        let stopping = active?.project == id
        let reason = stopping ? T("Clock out of %@", name(id)) : T("Clock in to %@", name(id))
        guard await authenticate(reason: reason, graceOK: graceOK) else { return }
        if stopping {
            stop()
        } else {
            start(id)
        }
    }

    func upsert(_ s: Session) {
        if let i = sessions.firstIndex(where: { $0.id == s.id }) {
            sessions[i] = s
        } else {
            sessions.append(s)
        }
        sessions.sort { $0.start < $1.start }
        save()
    }

    func delete(id: UUID) {
        sessions.removeAll { $0.id == id }
        save()
    }

    // Projects

    /// Returns a message if something is wrong, or nil when saved.
    func saveProject(_ draft: ProjectDef) -> String? {
        var p = draft
        p.name = p.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if p.name.isEmpty { return T("Give the project a name.") }
        if projects.contains(where: { $0.id != p.id && !$0.archived && $0.name.lowercased() == p.name.lowercased() }) {
            return T("You already have a project called %@.", p.name)
        }
        let isNew = !projects.contains { $0.id == p.id }
        if isNew && activeProjects.count >= 12 { return T("That is the limit: 12 projects.") }

        let typed = String(p.key.lowercased().filter { $0.isLetter || $0.isNumber }.prefix(1))
        p.key = typed
        p.globalShortcut = true   // every project always gets Control + its key
        if typed.isEmpty {
            p.key = autoKey(for: p.name, excluding: p.id)
        } else if typed == "w" {
            return T("Control+W is reserved for choosing a project. Pick another key.")
        } else if let other = activeProjects.first(where: { $0.id != p.id && $0.key == typed }) {
            return T("The key %@ is already used by %@.", typed.uppercased(), other.name)
        }
        if keyCodes[p.key] == nil { return T("That key cannot be used as a shortcut.") }

        if let i = projects.firstIndex(where: { $0.id == p.id }) {
            projects[i] = p
        } else {
            projects.append(p)
        }
        saveProjects()
        return nil
    }

    func autoKey(for name: String, excluding id: String) -> String {
        var used = Set(projects.filter { $0.id != id && !$0.archived }.map { $0.key })
        used.insert("w")   // Control + W is always "choose"
        let pool = name.lowercased().filter { $0.isLetter || $0.isNumber } + "abcdefghijklmnopqrstuvxyz0123456789"
        for c in pool where !used.contains(String(c)) && keyCodes[String(c)] != nil { return String(c) }
        return ""
    }

    /// With logged hours the project is archived (hours stay in the Log and Stats). Without, it is removed.
    func deleteProject(_ id: String) {
        guard active?.project != id else { return }
        guard let i = projects.firstIndex(where: { $0.id == id }) else { return }
        if hasHistory(id) {
            projects[i].archived = true
        } else {
            projects.remove(at: i)
        }
        saveProjects()
    }

    func restoreProject(_ id: String) {
        guard let i = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[i].archived = false
        let key = projects[i].key
        if key.isEmpty || projects.contains(where: { $0.id != id && !$0.archived && $0.key == key }) {
            projects[i].key = autoKey(for: projects[i].name, excluding: id)
        }
        saveProjects()
    }

    // Stats

    func seconds(_ p: String?, from: Date, to: Date) -> TimeInterval {
        sessions
            .filter { p == nil || $0.project == p }
            .reduce(0) { acc, s in
                let a = max(s.start, from)
                let b = min(s.end ?? now, to)
                return acc + max(0, b.timeIntervalSince(a))
            }
    }

    func averages(_ p: String?) -> (day: TimeInterval, week: TimeInterval, month: TimeInterval) {
        let mine = sessions.filter { p == nil || $0.project == p }
        guard let first = sessions.map(\.start).min() else { return (0, 0, 0) }
        let cal = Calendar.current
        let total = mine.reduce(0) { $0 + $1.duration(at: now) }

        var days = Set<Date>()
        for s in mine {
            var d = cal.startOfDay(for: s.start)
            let last = cal.startOfDay(for: s.end ?? now)
            while d <= last {
                days.insert(d)
                d = cal.date(byAdding: .day, value: 1, to: d)!
            }
        }

        let w0 = cal.dateInterval(of: .weekOfYear, for: first)!.start
        let w1 = cal.dateInterval(of: .weekOfYear, for: now)!.start
        let weeks = max(1, (cal.dateComponents([.weekOfYear], from: w0, to: w1).weekOfYear ?? 0) + 1)

        let m0 = cal.dateInterval(of: .month, for: first)!.start
        let m1 = cal.dateInterval(of: .month, for: now)!.start
        let months = max(1, (cal.dateComponents([.month], from: m0, to: m1).month ?? 0) + 1)

        return (total / Double(max(1, days.count)), total / Double(weeks), total / Double(months))
    }

    // Export

    func exportCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "work-log.csv"
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let dest = panel.url else { return }
        let iso = ISO8601DateFormatter()
        var out = "project,start,end,hours\n"
        for s in sessions.sorted(by: { $0.start < $1.start }) {
            let end = s.end.map { iso.string(from: $0) } ?? ""
            let label = name(s.project).replacingOccurrences(of: "\"", with: "\"\"")
            out += "\"\(label)\",\(iso.string(from: s.start)),\(end),\(String(format: "%.2f", s.duration(at: now) / 3600))\n"
        }
        try? out.write(to: dest, atomically: true, encoding: .utf8)
    }
}

// MARK: - Global hotkeys (no special permissions needed)

final class HotKeyCenter {
    static let shared = HotKeyCenter()
    var handlers: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef] = []
    private var installed = false
    private var nextID: UInt32 = 1

    func unregisterAll() {
        for r in refs { UnregisterEventHotKey(r) }
        refs.removeAll()
        handlers.removeAll()
    }

    func register(keyCode: Int, modifiers: Int, action: @escaping () -> Void) {
        if !installed {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
                var hk = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                  nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
                HotKeyCenter.shared.handlers[hk.id]?()
                return noErr
            }, 1, &spec, nil, nil)
            installed = true
        }
        let id = nextID
        nextID += 1
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers),
                                         EventHotKeyID(signature: OSType(0x57434B59), id: id),
                                         GetApplicationEventTarget(), 0, &ref)
        if status == noErr, let ref {
            handlers[id] = action
            refs.append(ref)
        }
    }
}

// MARK: - App shell (menu bar item, popover, chooser, project window)

@main
struct WorkClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

/// Small floating panel that asks what to start. Closes on Esc or when you click away.
final class ChooserPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override func resignKey() {
        super.resignKey()
        close()
    }
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let store = Store()
    var item: NSStatusItem!
    let popover = NSPopover()
    var chooser: ChooserPanel?
    var editorWindow: NSWindow?
    var tourWindow: NSWindow?
    var clickMonitor: Any?
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = item.button {
            b.action = #selector(togglePopover(_:))
            b.target = self
            b.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        }

        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: 340, height: 500)
        popover.contentViewController = NSHostingController(rootView: ContentView().environmentObject(store))

        Publishers.CombineLatest3(store.$now, store.$sessions, store.$projects)
            .sink { [weak self] _ in Task { @MainActor in self?.refreshTitle() } }
            .store(in: &cancellables)
        refreshTitle()

        // Re-register the keyboard shortcuts whenever the projects change.
        store.$projects
            .sink { [weak self] _ in Task { @MainActor in self?.registerHotkeys() } }
            .store(in: &cancellables)

        store.onNeedChoice = { [weak self] in
            guard let self else { return }
            let list = self.store.activeProjects
            if list.isEmpty {
                self.showProjectEditor(nil)
            } else if list.count == 1 {
                self.store.start(list[0].id)
            } else {
                self.showChooser()
            }
        }
        store.onEditProject = { [weak self] def in self?.showProjectEditor(def) }
        store.onShowTour = { [weak self] in self?.beginTour() }

        // Open at login by default, once the app lives in the Applications folder.
        if store.runsFromApplications && !UserDefaults.standard.bool(forKey: "loginSetupDone") {
            UserDefaults.standard.set(true, forKey: "loginSetupDone")
            store.setLaunchAtLogin(true)
        }

        // First start: show the quick instructions.
        if !UserDefaults.standard.bool(forKey: "onboardingDone") {
            UserDefaults.standard.set(true, forKey: "onboardingDone")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.showOnboarding() }
        }
    }

    /// Control + W always: clock out, or choose what to start.
    /// Control + letter for every project that has a shortcut. Each one asks for your fingerprint first.
    func registerHotkeys() {
        HotKeyCenter.shared.unregisterAll()
        HotKeyCenter.shared.register(keyCode: kVK_ANSI_W, modifiers: controlKey) { [weak self] in
            Task { @MainActor in await self?.store.primaryAction() }
        }
        for p in store.activeProjects {
            guard p.key != "w", let code = keyCodes[p.key] else { continue }
            let id = p.id
            HotKeyCenter.shared.register(keyCode: code, modifiers: controlKey) { [weak self] in
                Task { @MainActor in await self?.store.tap(id) }
            }
        }
    }

    func refreshTitle() {
        guard let b = item.button else { return }
        // Template image with no tint: macOS draws it in the same white as the other menu bar icons.
        let img = NSImage(systemSymbolName: store.active != nil ? "clock.fill" : "clock", accessibilityDescription: nil)
        img?.isTemplate = true
        b.image = img
        b.contentTintColor = nil
        if let a = store.active {
            b.title = " \(store.name(a.project).prefix(12)) \(clock(a.duration(at: store.now)))"
        } else {
            b.title = ""
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    /// Opens the menu bar window and starts the guided tour inside it.
    func beginTour() {
        tourWindow?.close()
        if !popover.isShown { showPopover() }
        store.tourStep = 0
    }

    func showPopover() {
        if let b = item.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: b.bounds, of: b, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()

            // Menu bar apps do not always get "click elsewhere to close" for free,
            // so close the window on any click outside it.
            if clickMonitor == nil {
                clickMonitor = NSEvent.addGlobalMonitorForEvents(
                    matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
                ) { [weak self] _ in
                    Task { @MainActor in self?.popover.performClose(nil) }
                }
            }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        store.tourStep = nil
        if let m = clickMonitor {
            NSEvent.removeMonitor(m)
            clickMonitor = nil
        }
    }

    func showChooser() {
        chooser?.close()
        let panel = ChooserPanel(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false

        let host = NSHostingView(rootView: ChooserView(projects: store.activeProjects) { [weak self, weak panel] id in
            panel?.close()
            if let id { self?.store.start(id) }
        })
        panel.contentView = host
        panel.setContentSize(host.fittingSize)
        panel.center()

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        chooser = panel
    }

    /// First-start instructions. Opens at the top right, close to the menu bar icon.
    func showOnboarding() {
        popover.performClose(nil)
        tourWindow?.close()
        let view = OnboardingView(start: { [weak self] in self?.beginTour() })
            .environmentObject(store)
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 380),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Tally"
        w.contentView = NSHostingView(rootView: view)
        w.isReleasedWhenClosed = false
        if let f = NSScreen.main?.visibleFrame {
            w.setFrameTopLeftPoint(NSPoint(x: f.maxX - 420 - 24, y: f.maxY - 12))
        } else {
            w.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        tourWindow = w
    }

    /// A normal window, so colour and image pickers can open without closing it.
    func showProjectEditor(_ def: ProjectDef?) {
        popover.performClose(nil)
        editorWindow?.close()
        let view = ProjectEditorView(existing: def, close: { [weak self] in self?.editorWindow?.close() })
            .environmentObject(store)
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 640),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = def == nil ? T("New project") : T("Edit project")
        w.contentView = NSHostingView(rootView: view)
        w.isReleasedWhenClosed = false
        w.center()
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: w, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.store.guideStep = nil }
        }
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        editorWindow = w
    }
}

// MARK: - Project looks

extension View {
    @ViewBuilder
    func optionalShortcut(_ c: Character?) -> some View {
        if let c {
            self.keyboardShortcut(KeyEquivalent(c), modifiers: [])
        } else {
            self
        }
    }
}

/// The logo, photo or name of a project, sized to a fixed slot so every card lines up.
struct ProjectFace: View {
    let p: ProjectDef
    var height: CGFloat = 36
    var maxWidth: CGFloat = 124
    var alignment: Alignment = .leading

    var body: some View {
        Group {
            if let img = ImageCache.image(for: p) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxWidth, maxHeight: height, alignment: alignment)
            } else {
                Text(p.name)
                    .font(.system(size: height * 0.5, weight: .bold, design: .rounded))
                    .foregroundStyle(p.onCard)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: maxWidth, alignment: alignment)
            }
        }
        .frame(height: height, alignment: alignment)
    }
}

/// Small square badge for a project. Used in the Log and the time editor.
struct ProjectBadge: View {
    let p: ProjectDef?
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28).fill(p?.card ?? Color.gray)
            if let p, let img = ImageCache.image(for: p), img.size.height > 0, img.size.width / img.size.height < 1.6 {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.1)
            } else {
                Text(String((p?.name ?? "?").prefix(1)).uppercased())
                    .font(.system(size: size * 0.55, weight: .heavy, design: .rounded))
                    .foregroundStyle(p?.tint ?? Color.white)
            }
        }
        .frame(width: size, height: size)
    }
}

/// The card look, without any behaviour. Used in the Track tab and as the preview in the project window.
struct ProjectCardView: View {
    let p: ProjectDef
    let caption: String
    let pill: String
    var running = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                ProjectFace(p: p, height: 36, maxWidth: 124)
                Text(caption)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(p.onCard.opacity(0.7))
                    .lineLimit(1)
            }
            Spacer()
            Text(pill)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(running ? p.onCard : p.accent))
                .foregroundStyle(running ? p.card : p.onAccent)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(p.card))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(running ? p.accent.opacity(0.9) : p.onCard.opacity(0.1), lineWidth: running ? 1.5 : 1))
    }
}

// MARK: - Chooser

struct ChooserView: View {
    let projects: [ProjectDef]
    var onPick: @MainActor (String?) -> Void

    var body: some View {
        let rows: [[ProjectDef]] = stride(from: 0, to: projects.count, by: 2).map {
            Array(projects[$0 ..< min($0 + 2, projects.count)])
        }

        VStack(spacing: 14) {
            Text(T("What are you starting?"))
                .font(.system(.headline, design: .rounded))

            VStack(spacing: 12) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: 12) {
                        ForEach(rows[r]) { p in card(p) }
                    }
                }
            }

            Text(T("Press a key to start. Esc to cancel."))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)

            Button("") { onPick(nil) }
                .keyboardShortcut(.cancelAction)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22).fill(.regularMaterial))
    }

    private func card(_ p: ProjectDef) -> some View {
        Button { onPick(p.id) } label: {
            VStack(spacing: 8) {
                ProjectFace(p: p, height: 46, maxWidth: 100, alignment: .center)
                if p.imagePNG != nil {
                    Text(p.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(p.onCard)
                        .lineLimit(1)
                }
                if !p.key.isEmpty {
                    Text(p.key.uppercased())
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(p.onCard)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(p.onCard.opacity(0.18)))
                }
            }
            .frame(width: 124)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(p.card))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(p.onCard.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .optionalShortcut(p.key.first)
    }
}

// MARK: - Main window (menu bar popover)

struct ContentView: View {
    enum Tab: CaseIterable {
        case track, stats, log, projects
        var icon: String {
            switch self {
            case .track: return "timer"
            case .stats: return "chart.bar.xaxis"
            case .log: return "calendar"
            case .projects: return "square.grid.2x2"
            }
        }
        var target: TourTarget {
            switch self {
            case .track: return .tabTrack
            case .stats: return .tabStats
            case .log: return .tabLog
            case .projects: return .tabProjects
            }
        }
        var title: String {
            switch self {
            case .track: return T("Track")
            case .stats: return T("Stats")
            case .log: return T("Log")
            case .projects: return T("Projects")
            }
        }
    }

    @EnvironmentObject var store: Store   // redraws the tabs when the language changes
    @State private var tab: Tab = .track

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .track: TrackView()
                case .stats: StatsView()
                case .log: LogView()
                case .projects: ProjectsView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 4) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button { tab = t } label: {
                        HStack(spacing: 6) {
                            Image(systemName: t.icon)
                            if tab == t { Text(t.title) }
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(tab == t ? Color.primary.opacity(0.1) : .clear))
                        .foregroundStyle(tab == t ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .tourTarget(t.target)
                }
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                Button { NSApp.terminate(nil) } label: {
                    Image(systemName: "power")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .help(T("Quit Tally"))
                .padding(.trailing, 6)
            }
        }
        .frame(width: 340, height: 500)
        .overlayPreferenceValue(TourKey.self) { anchors in
            TourOverlay(anchors: anchors)
        }
        .onChange(of: store.tourStep) { step in
            let steps = TourStep.all()
            if let step, step < steps.count { tab = steps[step].tab }
        }
    }
}

struct ProjectCard: View {
    @EnvironmentObject var store: Store
    let p: ProjectDef

    var body: some View {
        let running = store.active?.project == p.id
        let dayStart = Calendar.current.startOfDay(for: store.now)
        let hours = hm(store.seconds(p.id, from: dayStart, to: store.now))

        Button {
            Task { await store.tap(p.id, graceOK: true) }
        } label: {
            ProjectCardView(p: p,
                            caption: p.caption(hours: hours),
                            pill: running ? T("Clock out") : (store.active == nil ? T("Clock in") : T("Switch")),
                            running: running)
        }
        .buttonStyle(.plain)
    }
}

struct TrackView: View {
    @EnvironmentObject var store: Store

    private var hint: String {
        let parts = store.activeProjects
            .filter { !$0.key.isEmpty }
            .map { "⌃\($0.key.uppercased())  \($0.name)" }
        return (parts + ["⌃W  " + T("choose")]).joined(separator: "     ")
    }

    var body: some View {
        let list = store.activeProjects

        VStack(spacing: 14) {
            if let note = store.note {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill").foregroundStyle(.orange)
                    Text(note).font(.caption)
                    Spacer(minLength: 0)
                    Button { store.note = nil } label: { Image(systemName: "xmark") }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.12)))
            }

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                if let a = store.active {
                    Text(T("TRACKING %@", store.name(a.project).uppercased()))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(store.tint(a.project))
                        .lineLimit(1)
                    Text(clock(a.duration(at: store.now), seconds: true))
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text(T("since %@", shortTime(a.start)))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Text(T("READY"))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text("0:00:00")
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                    Text(list.isEmpty ? T("Add a project to start") : T("Pick a project to start"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if list.isEmpty {
                Button { store.onEditProject?(nil) } label: {
                    Label(T("Add your first project"), systemImage: "plus")
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tourTarget(.card)
                .padding(.bottom, 30)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(list) { p in ProjectCard(p: p).tourTarget(.card, enabled: p.id == list.first?.id) }
                        Button { store.onEditProject?(nil) } label: {
                            Label(T("New project"), systemImage: "plus")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                    }
                    .padding(2)
                }
                .frame(maxHeight: min(CGFloat(list.count) * 93 + 26, 300))

                Text(hint)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.title3, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.06)))
    }
}

struct DayBar: Identifiable {
    let id = UUID()
    let day: Date
    let project: String
    let hours: Double
}

struct StatsView: View {
    @EnvironmentObject var store: Store
    @State private var filter: String? = nil

    var body: some View {
        let cal = Calendar.current
        let n = store.now
        let periods: [(String, DateInterval)] = [
            (T("Today"), cal.dateInterval(of: .day, for: n)!),
            (T("This week"), cal.dateInterval(of: .weekOfYear, for: n)!),
            (T("This month"), cal.dateInterval(of: .month, for: n)!),
            (T("This year"), cal.dateInterval(of: .year, for: n)!)
        ]
        let avg = store.averages(filter)
        let shown = store.projects.filter { filter == nil || $0.id == filter }
        let chipProjects = store.projects.filter { !$0.archived || store.hasHistory($0.id) }

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        chip(T("All"), nil, Color.primary)
                        ForEach(chipProjects) { p in chip(p.name, p.id, p.tint) }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(T("Last 7 days")).font(.caption).foregroundStyle(.secondary)
                    Chart(bars()) { b in
                        BarMark(x: .value("Day", b.day, unit: .day), y: .value("Hours", b.hours))
                            .foregroundStyle(by: .value("Project", b.project))
                            .cornerRadius(4)
                    }
                    .chartForegroundStyleScale(domain: shown.map(\.id), range: shown.map(\.tint))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow).locale(Loc.current.locale))
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 100)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.06)))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(periods, id: \.0) { p in
                        StatCard(title: p.0, value: hm(store.seconds(filter, from: p.1.start, to: p.1.end)))
                    }
                }

                Text(T("Averages")).font(.system(.subheadline, design: .rounded, weight: .semibold))
                HStack(spacing: 10) {
                    StatCard(title: T("Per day"), value: hm(avg.day))
                    StatCard(title: T("Per week"), value: hm(avg.week))
                    StatCard(title: T("Per month"), value: hm(avg.month))
                }
                Text(T("Per day only counts days you worked. Weeks and months count from your first log."))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func chip(_ title: String, _ id: String?, _ tint: Color) -> some View {
        let selected = filter == id
        return Button { filter = id } label: {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(selected ? tint.opacity(0.18) : Color.primary.opacity(0.05)))
                .foregroundStyle(selected ? tint : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func bars() -> [DayBar] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: store.now)
        var out: [DayBar] = []
        for offset in (0..<7).reversed() {
            let d = cal.date(byAdding: .day, value: -offset, to: today)!
            let next = cal.date(byAdding: .day, value: 1, to: d)!
            for p in store.projects where filter == nil || filter == p.id {
                out.append(DayBar(day: d, project: p.id, hours: store.seconds(p.id, from: d, to: next) / 3600))
            }
        }
        return out
    }
}

// MARK: - Log and editing

struct Draft: Identifiable {
    var id: UUID
    var project: String
    var start: Date
    var end: Date
    var running: Bool
    var isNew: Bool
    var note: String = ""
}

struct LogView: View {
    @EnvironmentObject var store: Store
    @State private var editing: Draft?

    var body: some View {
        if let d = editing {
            EditorView(draft: d) { editing = nil }
        } else {
            list
        }
    }

    private var list: some View {
        let cal = Calendar.current
        let days = Set(store.sessions.map { cal.startOfDay(for: $0.start) }).sorted(by: >)

        return VStack(spacing: 10) {
            HStack {
                Text(T("Log")).font(.system(.title3, design: .rounded, weight: .semibold))
                Spacer()
                Button {
                    editing = Draft(id: UUID(), project: store.activeProjects.first?.id ?? "",
                                    start: Date().addingTimeInterval(-3600), end: Date(),
                                    running: false, isNew: true, note: "")
                } label: { Label(T("Add time"), systemImage: "plus") }
                    .buttonStyle(.borderless)
                    .disabled(store.activeProjects.isEmpty)
                Button { store.exportCSV() } label: { Image(systemName: "square.and.arrow.up") }
                    .buttonStyle(.borderless)
                    .help(T("Export CSV"))
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if days.isEmpty {
                        Text(T("Nothing logged yet.")).foregroundStyle(.secondary).padding(.top, 20)
                    }
                    ForEach(days, id: \.self) { day in
                        dayCard(day, cal)
                    }
                }
            }
        }
    }

    private func dayCard(_ day: Date, _ cal: Calendar) -> some View {
        let list = store.sessions
            .filter { cal.startOfDay(for: $0.start) == day }
            .sorted { $0.start > $1.start }
        let total = store.seconds(nil, from: day, to: cal.date(byAdding: .day, value: 1, to: day)!)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(day.formatted(.dateTime.weekday(.wide).day().month().locale(Loc.current.locale)))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Spacer()
                Text(hm(total)).font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(list) { s in
                Button {
                    editing = Draft(id: s.id, project: s.project, start: s.start,
                                    end: s.end ?? Date(), running: s.end == nil, isNew: false,
                                    note: s.note ?? "")
                } label: {
                    HStack(spacing: 8) {
                        ProjectBadge(p: store.def(s.project), size: 18)
                        Text(store.name(s.project))
                            .lineLimit(1)
                            .frame(width: 52, alignment: .leading)
                        Text(s.note ?? T("%@ to %@", shortTime(s.start), s.end.map(shortTime) ?? T("now")))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text(hm(s.duration(at: store.now)))
                    }
                    .font(.callout)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.06)))
    }
}

struct EditorView: View {
    @EnvironmentObject var store: Store
    @State var draft: Draft
    var close: () -> Void

    private var valid: Bool {
        guard store.def(draft.project) != nil else { return false }
        return draft.running ? draft.start < store.now : draft.end > draft.start
    }

    private var choices: [ProjectDef] {
        var list = store.activeProjects
        if let cur = store.def(draft.project), cur.archived { list.append(cur) }
        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(draft.isNew ? T("Add time") : T("Edit time"))
                .font(.system(.title3, design: .rounded, weight: .semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(choices) { p in
                        let sel = draft.project == p.id
                        Button { draft.project = p.id } label: {
                            HStack(spacing: 6) {
                                ProjectBadge(p: p, size: 20)
                                Text(p.name).lineLimit(1)
                            }
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(sel ? p.tint.opacity(0.2) : Color.primary.opacity(0.05)))
                            .foregroundStyle(sel ? p.tint : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            field(T("Start"), $draft.start)
            if draft.running {
                Text(T("Still running. Clock out to set the end time."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                field(T("End"), $draft.end)
                Text(valid ? T("Total: %@", hm(draft.end.timeIntervalSince(draft.start))) : T("End must be after start."))
                    .font(.caption)
                    .foregroundStyle(valid ? Color.secondary : Color.red)
            }

            TextField(T("Note (optional)"), text: $draft.note)
                .textFieldStyle(.roundedBorder)

            Spacer()

            HStack {
                if !draft.isNew {
                    Button(T("Delete"), role: .destructive) {
                        store.delete(id: draft.id)
                        close()
                    }
                }
                Spacer()
                Button(T("Cancel")) { close() }
                Button(T("Save")) {
                    store.upsert(Session(id: draft.id, project: draft.project,
                                         start: draft.start, end: draft.running ? nil : draft.end,
                                         note: draft.note.isEmpty ? nil : draft.note))
                    close()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!valid)
            }
        }
    }

    private func field(_ title: String, _ binding: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            DatePicker("", selection: binding, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.field)
                .labelsHidden()
        }
    }
}

// MARK: - Projects tab

struct ProjectsView: View {
    @EnvironmentObject var store: Store

    private func settingRow<C: View>(_ title: String, @ViewBuilder control: () -> C) -> some View {
        HStack {
            Text(title).font(.callout)
            Spacer()
            control().labelsHidden().toggleStyle(.switch)
        }
        .padding(.vertical, 8)
    }

    private func shortcutRow(_ label: String, _ keys: String) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.callout).foregroundStyle(.secondary).lineLimit(1)
            Spacer()
            Text(keys)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(0.1)))
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 8)
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(T("Projects")).font(.system(.title3, design: .rounded, weight: .semibold))
                    Spacer()
                    Button { store.onEditProject?(nil) } label: { Label(T("New project"), systemImage: "plus") }
                        .buttonStyle(.borderless)
                        .tourTarget(.newProject)
                }

                if store.activeProjects.isEmpty {
                    Text(T("No projects yet. Add one to start tracking."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                }

                ForEach(store.activeProjects) { p in
                    Button { store.onEditProject?(p) } label: {
                        HStack {
                            ProjectFace(p: p, height: 28, maxWidth: 120)
                            Spacer()
                            Text(hm(store.hoursLogged(p.id)))
                                .font(.caption)
                                .foregroundStyle(p.onCard.opacity(0.7))
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(p.onCard.opacity(0.6))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(p.card))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if !store.archivedProjects.isEmpty {
                    Text(T("Archived"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    ForEach(store.archivedProjects) { p in
                        HStack(spacing: 8) {
                            ProjectBadge(p: p, size: 22)
                            Text(p.name).lineLimit(1)
                            Spacer()
                            Text(hm(store.hoursLogged(p.id))).font(.caption).foregroundStyle(.secondary)
                            Button(T("Restore")) { store.restoreProject(p.id) }
                                .buttonStyle(.borderless)
                        }
                        .font(.callout)
                    }
                    Text(T("Hours of archived projects stay in your Log and Stats."))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(T("Settings"))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 0) {
                    settingRow(T("Use Touch ID")) { Toggle("", isOn: $store.useTouchID) }
                    if !store.useTouchID {
                        note(T("Off: no fingerprint is asked. Use this if your Mac has no Touch ID."))
                    }
                    Divider()
                    settingRow(T("Open at login")) {
                        Toggle("", isOn: Binding(get: { store.launchAtLoginEnabled },
                                                 set: { store.setLaunchAtLogin($0) }))
                            .disabled(!store.runsFromApplications)
                    }
                    if !store.runsFromApplications {
                        note(T("To turn this on, put Tally in your Applications folder and open it from there."))
                    } else if store.launchAtLoginNeedsApproval {
                        note(T("macOS needs your OK in System Settings > General > Login Items."))
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(T("Language")).font(.callout)
                        Picker("", selection: $store.language) {
                            ForEach(AppLang.allCases) { l in Text(l.label).tag(l) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding(.vertical, 10)
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(T("Shortcuts")).font(.callout)
                        ForEach(store.activeProjects.filter { !$0.key.isEmpty }) { p in
                            shortcutRow(p.name, "⌃ " + p.key.uppercased())
                        }
                        shortcutRow(T("Clock out, or choose what to start"), "⌃ W")
                    }
                    .padding(.vertical, 10)
                    Divider()
                    Button { store.onShowTour?() } label: {
                        HStack {
                            Text(T("Show quick instructions")).font(.callout)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.06)))
                .tourTarget(.settings)
                .id("settings")

                // Quiet credit at the very end
                VStack(spacing: 2) {
                    Text(T("Made by Gil Nobre"))
                    HStack(spacing: 4) {
                        Text(T("Feedback or feature suggestions:"))
                        Link("pupal08.ribbons@icloud.com", destination: URL(string: "mailto:pupal08.ribbons@icloud.com")!)
                    }
                }
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                Text("Created by Gil Nobre")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }
        }
        .onChange(of: store.tourStep) { step in
            if step == 1 { withAnimation { proxy.scrollTo("settings", anchor: .center) } }
        }
        }
    }
}

// MARK: - Project window (new, edit, delete)

struct ProjectEditorView: View {
    @EnvironmentObject var store: Store
    let existing: ProjectDef?
    var close: () -> Void

    @State private var draft: ProjectDef
    @State private var hexText: String
    @State private var problem: String?
    @State private var showDelete = false
    @State private var confirmText = ""
    @State private var keyTouched: Bool

    private let swatches = ["000000", "1F2937", "1D4ED8", "0F766E", "15803D", "CA8A04",
                            "EA580C", "DC2626", "BE185D", "6D28D9", "3A1019", "E5E7EB"]

    init(existing: ProjectDef?, close: @escaping () -> Void) {
        self.existing = existing
        self.close = close
        let d = existing ?? ProjectDef(id: UUID().uuidString, name: "", cardHex: "1D4ED8")
        _draft = State(initialValue: d)
        _hexText = State(initialValue: d.cardHex)
        _keyTouched = State(initialValue: existing != nil)   // only auto-suggest for new projects
    }

    private var preview: ProjectDef {
        var p = draft
        if p.name.trimmingCharacters(in: .whitespaces).isEmpty { p.name = T("Project name") }
        return p
    }

    private var isRunning: Bool { store.active?.project == draft.id }

    /// The key field. Typing a new letter replaces the old one.
    private var keyBinding: Binding<String> {
        Binding(get: { draft.key.uppercased() },
                set: { v in
                    keyTouched = true
                    draft.key = String(v.lowercased().filter { $0.isLetter || $0.isNumber }.suffix(1))
                })
    }

    private var keyProblem: String? {
        let k = draft.key
        if k.isEmpty { return nil }
        if k == "w" { return T("Control+W is reserved for choosing a project. Pick another key.") }
        if let other = store.activeProjects.first(where: { $0.id != draft.id && $0.key == k }) {
            return T("The key %@ is already used by %@.", k.uppercased(), other.name)
        }
        return nil
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProjectCardView(p: preview, caption: preview.caption(hours: "0m"), pill: T("Clock in"))

                VStack(alignment: .leading, spacing: 6) {
                    Text(T("Name")).font(.caption).foregroundStyle(.secondary)
                    TextField(T("For example: Writing, Client work, Gym"), text: $draft.name)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: draft.name) { v in
                            if v.count > 24 { draft.name = String(v.prefix(24)) }
                            if !keyTouched {
                                draft.key = v.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? "" : store.autoKey(for: draft.name, excluding: draft.id)
                            }
                        }
                }
                .tourTarget(.guideName)
                .id("g0")

                VStack(alignment: .leading, spacing: 8) {
                    Text(T("Colour")).font(.caption).foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 10), count: 6),
                              alignment: .leading, spacing: 10) {
                        ForEach(swatches, id: \.self) { hex in
                            Button { setColour(hex) } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1))
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(perceivedBrightness(hex) > 0.62 ? Color.black : Color.white)
                                            .opacity(draft.cardHex.uppercased() == hex ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(T("Or a custom colour")).font(.caption).foregroundStyle(.secondary)
                        TextField("#RRGGBB", text: $hexText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: hexText) { v in
                                if isValidHex(v) {
                                    let h = normalizedHex(v)
                                    if h != draft.cardHex { setColour(h, updateText: false) }
                                }
                            }
                    }
                }
                .tourTarget(.guideColour)
                .id("g1")

                VStack(alignment: .leading, spacing: 8) {
                    Text(T("Logo or photo (optional)")).font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        ProjectBadge(p: preview, size: 44)
                        Button(T("Choose image…")) { chooseImage() }
                        if draft.imagePNG != nil {
                            Button(T("Remove")) { draft.imagePNG = nil }
                        }
                    }
                    Text(T("It shows on the card. Wide logos and square photos both work."))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .tourTarget(.guideImage)
                .id("g2")

                VStack(alignment: .leading, spacing: 8) {
                    Text(T("Shortcut")).font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text("Control +").font(.system(.body, design: .rounded, weight: .semibold))
                        TextField("", text: keyBinding)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                    }
                    if let msg = keyProblem {
                        Text(msg).font(.caption).foregroundStyle(.red)
                    }
                    Text(T("Starts and stops this project from anywhere. Control + W is always \"choose\"."))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .tourTarget(.guideShortcut)
                .id("g3")

                if let problem {
                    Text(problem).font(.callout).foregroundStyle(.red)
                }

                HStack {
                    Spacer()
                    Button(T("Cancel")) { close() }
                    Button(T("Save")) {
                        if let msg = store.saveProject(draft) {
                            problem = msg
                        } else {
                            close()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || keyProblem != nil)
                    .tourTarget(.guideSave)
                    .id("g4")
                }

                if existing != nil {
                    Divider()
                    deleteSection
                }
            }
            .padding(22)
        }
        .frame(width: 440, height: 640)
        .onChange(of: store.guideStep) { step in
            if let step { withAnimation { proxy.scrollTo("g\(step)", anchor: .center) } }
        }
        }
        .overlayPreferenceValue(TourKey.self) { anchors in
            guideOverlay(anchors)
        }
    }

    // Step-by-step walkthrough. It never blocks the form, so you can type and click while it points.

    private struct GuideStep {
        let target: TourTarget
        let title: String
        let text: String
    }

    private var guideSteps: [GuideStep] {
        [
            GuideStep(target: .guideName, title: T("Name it"),
                      text: T("Type a name for your project, for example Writing or Client work. Then tap Next.")),
            GuideStep(target: .guideColour, title: T("Pick a colour"),
                      text: T("Choose a colour for the card. The preview at the top changes as you go.")),
            GuideStep(target: .guideImage, title: T("Add a logo or photo"),
                      text: T("Optional. Tap Choose image to use a logo or a photo, or just tap Next to skip.")),
            GuideStep(target: .guideShortcut, title: T("Your shortcut"),
                      text: T("This key is suggested from the name. Press Control + this key anywhere to clock in or out. You can change it.")),
            GuideStep(target: .guideSave, title: T("Save it"),
                      text: T("Tap Save. Your project appears on the Track tab, ready to use."))
        ]
    }

    @ViewBuilder
    private func guideOverlay(_ anchors: [TourTarget: Anchor<CGRect>]) -> some View {
        let steps = guideSteps
        if let i = store.guideStep, i < steps.count {
            GeometryReader { geo in
                let rect: CGRect? = anchors[steps[i].target].map { geo[$0] }
                ZStack {
                    Color.black.opacity(0.38)
                        .mask(
                            ZStack {
                                Rectangle()
                                if let r = rect {
                                    RoundedRectangle(cornerRadius: 12)
                                        .frame(width: r.width + 16, height: r.height + 16)
                                        .position(x: r.midX, y: r.midY)
                                        .blendMode(.destinationOut)
                                }
                            }
                            .compositingGroup()
                        )
                        .allowsHitTesting(false)
                    if let r = rect {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .frame(width: r.width + 16, height: r.height + 16)
                            .position(x: r.midX, y: r.midY)
                            .allowsHitTesting(false)
                    }
                    VStack {
                        if (rect?.midY ?? 0) > geo.size.height * 0.5 {
                            guideCard(i, steps)
                            Spacer()
                        } else {
                            Spacer()
                            guideCard(i, steps)
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    private func guideCard(_ i: Int, _ steps: [GuideStep]) -> some View {
        let st = steps[i]
        let nameEmpty = draft.name.trimmingCharacters(in: .whitespaces).isEmpty
        return VStack(alignment: .leading, spacing: 10) {
            Text(st.title).font(.system(.headline, design: .rounded))
            Text(st.text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if i > 0 {
                    Button(T("Back")) { store.guideStep = i - 1 }.buttonStyle(.borderless)
                } else {
                    Button(T("Skip")) { store.guideStep = nil }.buttonStyle(.borderless)
                }
                Spacer()
                HStack(spacing: 5) {
                    ForEach(0..<steps.count, id: \.self) { n in
                        Circle()
                            .fill(n == i ? Color.primary : Color.primary.opacity(0.2))
                            .frame(width: 5, height: 5)
                    }
                }
                Spacer()
                if i < steps.count - 1 {
                    Button(T("Next")) { store.guideStep = i + 1 }
                        .buttonStyle(.borderedProminent)
                        .disabled(i == 0 && nameEmpty)
                } else {
                    Button(T("Got it")) { store.guideStep = nil }.buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.15), lineWidth: 1))
        .shadow(radius: 12, y: 4)
    }

    @ViewBuilder
    private var deleteSection: some View {
        if !showDelete {
            Button(T("Delete this project…")) { showDelete = true }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
        } else {
            let logged = store.hoursLogged(draft.id)
            VStack(alignment: .leading, spacing: 10) {
                if logged > 0 {
                    Text(T("%@ is logged on this project. It stays in your Log and Stats, and the project moves to Archived, where you can restore it any time.", hm(logged)))
                        .font(.callout)
                } else {
                    Text(T("Nothing is logged on this project, so it will be removed."))
                        .font(.callout)
                }
                if isRunning {
                    Text(T("This project is running. Clock out first."))
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                TextField(T("Type \"%@\" to confirm", draft.name), text: $confirmText)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button(T("Keep project")) { showDelete = false; confirmText = "" }
                    Spacer()
                    Button(T("Delete project"), role: .destructive) {
                        store.deleteProject(draft.id)
                        close()
                    }
                    .disabled(isRunning || confirmText != (existing?.name ?? "\u{0}"))
                }
            }
        }
    }

    private func setColour(_ hex: String, updateText: Bool = true) {
        draft.cardHex = hex
        draft.accentHex = nil
        draft.tintHex = nil
        if updateText { hexText = hex }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url,
              let img = NSImage(contentsOf: url), let data = pngData(from: img) else { return }
        draft.imagePNG = data
    }
}

// MARK: - Welcome window and guided tour

/// First start only: points at the menu bar icon, lets you pick a language, then starts the tour.
struct OnboardingView: View {
    @EnvironmentObject var store: Store
    var start: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                Image(systemName: "arrow.up")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 24)
            }
            Text(T("Welcome to Tally"))
                .font(.system(.title, design: .rounded, weight: .bold))
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 22, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.primary.opacity(0.1)))
                Text(T("Click this icon in your menu bar"))
                    .font(.system(.headline, design: .rounded))
            }
            Text(T("This is where Tally lives. Choose your language, then start the quick instructions."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Picker("", selection: $store.language) {
                ForEach(AppLang.allCases) { l in Text(l.label).tag(l) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            Spacer(minLength: 0)
            Button(T("Start quick instructions")) { start() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(24)
        .frame(width: 420, height: 380)
    }
}

/// Things in the menu bar window that the tour can point at.
enum TourTarget: Hashable {
    case newProject, settings, card, tabTrack, tabStats, tabLog, tabProjects
    case guideName, guideColour, guideImage, guideShortcut, guideSave
}

struct TourKey: PreferenceKey {
    static var defaultValue: [TourTarget: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TourTarget: Anchor<CGRect>], nextValue: () -> [TourTarget: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    func tourTarget(_ t: TourTarget, enabled: Bool = true) -> some View {
        anchorPreference(key: TourKey.self, value: .bounds) { enabled ? [t: $0] : [:] }
    }
}

struct TourStep {
    let tab: ContentView.Tab
    let target: TourTarget?
    let title: String
    let text: String

    static func all(hasProjects: Bool = true) -> [TourStep] {
        [
            TourStep(tab: .projects, target: .newProject, title: T("Add a project"),
                     text: T("This is where you add and edit projects. We will create one together at the end.")),
            TourStep(tab: .projects, target: .settings, title: T("Your settings"),
                     text: T("Turn Touch ID on or off, change the language and choose if Tally opens at login.")),
            TourStep(tab: .track, target: .card, title: T("Clock in and out"),
                     text: T("Tap a project to clock in. Tap it again to clock out. Or press Control + its key from anywhere. Control + W lets you choose.")),
            TourStep(tab: .stats, target: .tabStats, title: T("See your hours"),
                     text: T("Stats shows totals and averages for each project.")),
            TourStep(tab: .log, target: .tabLog, title: T("Fix your log"),
                     text: T("Log lets you edit or add time by hand. Going to sleep stops the clock for you.")),
            hasProjects
                ? TourStep(tab: .track, target: nil, title: T("You're all set"),
                           text: T("Tally opens at login. Press Control + W any time to start. Want to practise? We can create a project together, step by step."))
                : TourStep(tab: .track, target: nil, title: T("Create your first project"),
                           text: T("Let's make your first one together, step by step."))
        ]
    }
}

/// Dims the menu bar window, rings the thing to look at and explains it.
struct TourOverlay: View {
    @EnvironmentObject var store: Store
    let anchors: [TourTarget: Anchor<CGRect>]

    var body: some View {
        GeometryReader { geo in
            let steps = TourStep.all(hasProjects: !store.activeProjects.isEmpty)
            if let index = store.tourStep, index < steps.count {
                let step = steps[index]
                let rect: CGRect? = step.target.flatMap { anchors[$0] }.map { geo[$0] }
                ZStack {
                    Color.black.opacity(0.62)
                        .mask(
                            ZStack {
                                Rectangle()
                                if let r = rect {
                                    RoundedRectangle(cornerRadius: 14)
                                        .frame(width: r.width + 12, height: r.height + 12)
                                        .position(x: r.midX, y: r.midY)
                                        .blendMode(.destinationOut)
                                }
                            }
                            .compositingGroup()
                        )
                    if let r = rect {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: r.width + 12, height: r.height + 12)
                            .position(x: r.midX, y: r.midY)
                            .allowsHitTesting(false)
                    }
                    VStack {
                        if let r = rect {
                            if r.midY > geo.size.height * 0.45 {
                                card(index, step, total: steps.count)
                                Spacer()
                            } else {
                                Spacer()
                                card(index, step, total: steps.count)
                            }
                        } else {
                            Spacer()
                            card(index, step, total: steps.count)
                            Spacer()
                        }
                    }
                    .padding(12)
                }
            }
        }
    }

    private func card(_ index: Int, _ step: TourStep, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.title).font(.system(.headline, design: .rounded))
            Text(step.text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if index > 0 {
                    Button(T("Back")) { store.tourStep = index - 1 }.buttonStyle(.borderless)
                } else {
                    Button(T("Skip")) { store.tourStep = nil }.buttonStyle(.borderless)
                }
                Spacer()
                HStack(spacing: 5) {
                    ForEach(0..<total, id: \.self) { i in
                        Circle()
                            .fill(i == index ? Color.primary : Color.primary.opacity(0.2))
                            .frame(width: 5, height: 5)
                    }
                }
                Spacer()
                if index < total - 1 {
                    Button(T("Next")) { store.tourStep = index + 1 }.buttonStyle(.borderedProminent)
                } else {
                    HStack(spacing: 8) {
                        if !store.activeProjects.isEmpty {
                            Button(T("Done")) { store.tourStep = nil }.buttonStyle(.borderless)
                        }
                        Button(store.activeProjects.isEmpty ? T("Create first project") : T("Create a project")) {
                            store.tourStep = nil
                            store.startProjectGuide()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.12), lineWidth: 1))
        .shadow(radius: 12, y: 4)
    }
}
