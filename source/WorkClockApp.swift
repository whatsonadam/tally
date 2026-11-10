// Tally, created by Gil.
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
    case en, pt, es, nl, fr, de, it
    var id: String { rawValue }

    /// The languages behind the "Others" choice.
    static let others: [AppLang] = [.nl, .fr, .de, .it]

    /// Portuguese means European Portuguese.
    var label: String {
        switch self {
        case .en: return "English"
        case .pt: return "Português"
        case .es: return "Español"
        case .nl: return "Nederlands"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .it: return "Italiano"
        }
    }

    var locale: Locale {
        switch self {
        case .en: return Locale(identifier: "en")
        case .pt: return Locale(identifier: "pt_PT")
        case .es: return Locale(identifier: "es")
        case .nl: return Locale(identifier: "nl")
        case .fr: return Locale(identifier: "fr")
        case .de: return Locale(identifier: "de")
        case .it: return Locale(identifier: "it")
        }
    }

    /// The Mac's own language, used until you pick one.
    static var system: AppLang {
        let first = (Locale.preferredLanguages.first ?? "en").lowercased()
        if first.hasPrefix("pt") { return .pt }
        if first.hasPrefix("es") { return .es }
        if first.hasPrefix("nl") { return .nl }
        if first.hasPrefix("fr") { return .fr }
        if first.hasPrefix("de") { return .de }
        if first.hasPrefix("it") { return .it }
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
    switch Loc.current {
    case .en: break
    case .pt: if let row = translations[key] { s = row.pt }
    case .es: if let row = translations[key] { s = row.es }
    case .nl: s = translationsNL[key] ?? key
    case .fr: s = translationsFR[key] ?? key
    case .de: s = translationsDE[key] ?? key
    case .it: s = translationsIT[key] ?? key
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
    "Made by Gil": (pt: "Feito por Gil", es: "Hecho por Gil"),
    "Others": (pt: "Outros", es: "Otros"),
    "Thanks for installing Tally! I hope it helps you manage your work. It is designed to be a very, very simple app. For any feedback or extra features, contact me at:":
        (pt: "Obrigado por instalares o Tally! Espero que te ajude a gerir o teu trabalho. Foi pensado para ser uma app muito, muito simples. Para qualquer feedback ou funcionalidades extra, contacta-me em:",
         es: "¡Gracias por instalar Tally! Espero que te ayude a gestionar tu trabajo. Está pensada para ser una app muy, muy sencilla. Para cualquier comentario o función extra, escríbeme a:"),
    "Feedback or feature suggestions:": (pt: "Feedback ou sugestões:", es: "Comentarios o sugerencias:"),
    "Clock out, or choose what to start": (pt: "Parar, ou escolher o que começar", es: "Parar, o elegir qué empezar"),
    "Show quick instructions": (pt: "Ver instruções rápidas", es: "Ver instrucciones rápidas"),
    "Totals": (pt: "Totais", es: "Totales"),
    "Your data": (pt: "Os teus dados", es: "Tus datos"),
    "Back up": (pt: "Guardar cópia", es: "Copia de seguridad"),
    "Import": (pt: "Importar", es: "Importar"),
    "Move your hours to a new Mac, or restore them after a reinstall.": (pt: "Muda as tuas horas para um novo Mac, ou recupera-as depois de reinstalar.", es: "Lleva tus horas a un Mac nuevo, o recupéralas tras reinstalar."),
    "Backup saved.": (pt: "Cópia guardada.", es: "Copia guardada."),
    "Choose a Tally backup file, or a data folder.": (pt: "Escolhe um ficheiro de cópia do Tally, ou uma pasta de dados.", es: "Elige un archivo de copia de Tally, o una carpeta de datos."),
    "That does not look like Tally data.": (pt: "Isto não parece ser dados do Tally.", es: "Esto no parece ser datos de Tally."),
    "Replace your current data?": (pt: "Substituir os dados atuais?", es: "¿Reemplazar tus datos actuales?"),
    "Import %d sessions? A safety copy of your current data stays in the data folder.": (pt: "Importar %d sessões? Fica uma cópia de segurança dos dados atuais na pasta de dados.", es: "¿Importar %d sesiones? Queda una copia de seguridad de tus datos actuales en la carpeta de datos."),
    "Imported %d sessions.": (pt: "%d sessões importadas.", es: "%d sesiones importadas."),
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

private let translationsNL: [String: String] = [
    "Your log file could not be read. A copy was kept in the data folder.": "Je logbestand kon niet worden gelezen. Er is een kopie bewaard in de gegevensmap.",
    "Your last session was closed at %@ because the app restarted. You can edit it in the Log.": "Je laatste sessie is om %@ afgesloten omdat de app opnieuw is gestart. Je kunt hem aanpassen in het Logboek.",
    "Stopped %@ at %@ when your Mac went to sleep.": "%@ is om %@ gestopt toen je Mac in slaapstand ging.",
    "Could not change the open at login setting: %@": "Kon de instelling voor openen bij inloggen niet wijzigen: %@",
    "Open Tally": "Tally openen",
    "Clock out of %@": "%@ stoppen",
    "Clock in": "Start",
    "Clock in to %@": "Starten met %@",
    "Give the project a name.": "Geef het project een naam.",
    "You already have a project called %@.": "Je hebt al een project met de naam %@.",
    "That is the limit: 12 projects.": "Dat is de limiet: 12 projecten.",
    "The key %@ is already used by %@.": "De toets %@ wordt al gebruikt door %@.",
    "Control+W is reserved for choosing a project. Pick another key.": "Control+W is gereserveerd voor het kiezen van een project. Kies een andere toets.",
    "That key cannot be used as a shortcut.": "Die toets kan niet als sneltoets worden gebruikt.",
    "Project name": "Projectnaam",
    "%@ today": "%@ vandaag",
    "What are you starting?": "Waar begin je mee?",
    "Press a key to start. Esc to cancel.": "Druk op een toets om te starten. Esc om te annuleren.",
    "Track": "Tijd",
    "Stats": "Cijfers",
    "Log": "Logboek",
    "Projects": "Projecten",
    "Quit Tally": "Tally afsluiten",
    "TRACKING %@": "BEZIG MET %@",
    "since %@": "sinds %@",
    "READY": "KLAAR",
    "Add a project to start": "Voeg een project toe om te starten",
    "Pick a project to start": "Kies een project om te starten",
    "Add your first project": "Voeg je eerste project toe",
    "Clock out": "Stop",
    "Switch": "Wissel",
    "choose": "kiezen",
    "New project": "Nieuw project",
    "Today": "Vandaag",
    "This week": "Deze week",
    "This month": "Deze maand",
    "This year": "Dit jaar",
    "All": "Alles",
    "Last 7 days": "Laatste 7 dagen",
    "Averages": "Gemiddelden",
    "Per day": "Per dag",
    "Per week": "Per week",
    "Per month": "Per maand",
    "Per day only counts days you worked. Weeks and months count from your first log.": "Per dag telt alleen dagen waarop je werkte. Weken en maanden tellen vanaf je eerste registratie.",
    "Nothing logged yet.": "Nog niets geregistreerd.",
    "Add time": "Tijd toevoegen",
    "Edit time": "Tijd aanpassen",
    "Export CSV": "CSV exporteren",
    "%@ to %@": "%@ tot %@",
    "now": "nu",
    "Start": "Begin",
    "End": "Einde",
    "Still running. Clock out to set the end time.": "Loopt nog. Stop de klok om de eindtijd in te stellen.",
    "Total: %@": "Totaal: %@",
    "End must be after start.": "Het einde moet na het begin liggen.",
    "Note (optional)": "Notitie (optioneel)",
    "Delete": "Verwijderen",
    "Cancel": "Annuleren",
    "Save": "Bewaren",
    "No projects yet. Add one to start tracking.": "Nog geen projecten. Voeg er een toe om te beginnen.",
    "Archived": "Gearchiveerd",
    "Restore": "Herstellen",
    "Hours of archived projects stay in your Log and Stats.": "Uren van gearchiveerde projecten blijven in je Logboek en Cijfers.",
    "Settings": "Instellingen",
    "Use Touch ID": "Touch ID gebruiken",
    "Off: no fingerprint is asked. Use this if your Mac has no Touch ID.": "Uit: er wordt geen vingerafdruk gevraagd. Gebruik dit als je Mac geen Touch ID heeft.",
    "Language": "Taal",
    "Shortcuts": "Sneltoetsen",
    "Made by Gil": "Gemaakt door Gil",
    "Feedback or feature suggestions:": "Feedback of ideeën voor functies:",
    "Clock out, or choose what to start": "Stoppen, of kiezen wat je start",
    "Show quick instructions": "Snelle uitleg tonen",
    "Totals": "Totalen",
    "Your data": "Je gegevens",
    "Back up": "Back-up maken",
    "Import": "Importeren",
    "Move your hours to a new Mac, or restore them after a reinstall.": "Verhuis je uren naar een nieuwe Mac, of herstel ze na een herinstallatie.",
    "Backup saved.": "Back-up opgeslagen.",
    "Choose a Tally backup file, or a data folder.": "Kies een Tally-back-upbestand of een gegevensmap.",
    "That does not look like Tally data.": "Dit lijkt geen Tally-gegevens.",
    "Replace your current data?": "Je huidige gegevens vervangen?",
    "Import %d sessions? A safety copy of your current data stays in the data folder.": "%d sessies importeren? Een reservekopie van je huidige gegevens blijft in de gegevensmap.",
    "Imported %d sessions.": "%d sessies geïmporteerd.",
    "Open at login": "Openen bij inloggen",
    "To turn this on, put Tally in your Applications folder and open it from there.": "Zet Tally hiervoor in je map Programma's en open het vanaf daar.",
    "macOS needs your OK in System Settings > General > Login Items.": "macOS heeft je toestemming nodig in Systeeminstellingen > Algemeen > Inloggen.",
    "Edit project": "Project aanpassen",
    "Name": "Naam",
    "For example: Writing, Client work, Gym": "Bijvoorbeeld: Schrijven, Klantwerk, Sportschool",
    "Colour": "Kleur",
    "Or a custom colour": "Of een eigen kleur",
    "Logo or photo (optional)": "Logo of foto (optioneel)",
    "Choose image…": "Afbeelding kiezen…",
    "Remove": "Verwijderen",
    "It shows on the card. Wide logos and square photos both work.": "Het staat op de kaart. Brede logo's en vierkante foto's werken allebei.",
    "Shortcut": "Sneltoets",
    "Starts and stops this project from anywhere. Control + W is always \"choose\".": "Start en stopt dit project vanaf overal. Control + W is altijd “kiezen”.",
    "Delete this project…": "Dit project verwijderen…",
    "%@ is logged on this project. It stays in your Log and Stats, and the project moves to Archived, where you can restore it any time.": "%@ is geregistreerd op dit project. Het blijft in je Logboek en Cijfers, en het project gaat naar Gearchiveerd, waar je het altijd kunt herstellen.",
    "Nothing is logged on this project, so it will be removed.": "Er is niets geregistreerd op dit project, dus het wordt verwijderd.",
    "This project is running. Clock out first.": "Dit project loopt. Stop eerst de klok.",
    "Type \"%@\" to confirm": "Typ “%@” om te bevestigen",
    "Keep project": "Project behouden",
    "Delete project": "Project verwijderen",
    "Welcome to Tally": "Welkom bij Tally",
    "Click this icon in your menu bar": "Klik op dit icoon in je menubalk",
    "This is where Tally lives. Choose your language, then start the quick instructions.": "Hier woont Tally. Kies je taal en start de snelle uitleg.",
    "Start quick instructions": "Snelle uitleg starten",
    "Add a project": "Voeg een project toe",
    "This is where you add and edit projects. We will create one together at the end.": "Hier voeg je projecten toe en pas je ze aan. Aan het eind maken we er samen een.",
    "Tally opens at login. Press Control + W any time to start. Want to practise? We can create a project together, step by step.": "Tally opent bij het inloggen. Druk altijd op Control + W om te starten. Wil je oefenen? We kunnen samen stap voor stap een project maken.",
    "Let's make your first one together, step by step.": "Laten we samen je eerste maken, stap voor stap.",
    "Create a project": "Project maken",
    "Name it": "Geef het een naam",
    "Type a name for your project, for example Writing or Client work. Then tap Next.": "Typ een naam voor je project, bijvoorbeeld Schrijven of Klantwerk. Tik daarna op Volgende.",
    "Pick a colour": "Kies een kleur",
    "Choose a colour for the card. The preview at the top changes as you go.": "Kies een kleur voor de kaart. Het voorbeeld bovenaan verandert mee.",
    "Add a logo or photo": "Voeg een logo of foto toe",
    "Optional. Tap Choose image to use a logo or a photo, or just tap Next to skip.": "Optioneel. Tik op Afbeelding kiezen voor een logo of foto, of tik op Volgende om over te slaan.",
    "Your shortcut": "Je sneltoets",
    "This key is suggested from the name. Press Control + this key anywhere to clock in or out. You can change it.": "Deze toets is voorgesteld op basis van de naam. Druk overal op Control + deze toets om te starten of stoppen. Je kunt hem aanpassen.",
    "Save it": "Bewaar het",
    "Tap Save. Your project appears on the Track tab, ready to use.": "Tik op Bewaren. Je project verschijnt op het tabblad Tijd, klaar voor gebruik.",
    "Got it": "Begrepen",
    "Your settings": "Je instellingen",
    "Turn Touch ID on or off, change the language and choose if Tally opens at login.": "Zet Touch ID aan of uit, wijzig de taal en kies of Tally bij het inloggen opent.",
    "Clock in and out": "In- en uitklokken",
    "Tap a project to clock in. Tap it again to clock out. Or press Control + its key from anywhere. Control + W lets you choose.": "Tik op een project om te starten. Tik nogmaals om te stoppen. Of druk overal op Control + de toets ervan. Met Control + W kies je.",
    "See your hours": "Bekijk je uren",
    "Stats shows totals and averages for each project.": "Cijfers toont totalen en gemiddelden per project.",
    "Fix your log": "Pas je logboek aan",
    "Log lets you edit or add time by hand. Going to sleep stops the clock for you.": "In het Logboek pas je tijd handmatig aan of voeg je die toe. Als je Mac in slaap gaat, stopt de klok vanzelf.",
    "You're all set": "Alles klaar",
    "Create your first project": "Maak je eerste project",
    "Create first project": "Eerste project maken",
    "Skip": "Overslaan",
    "Back": "Terug",
    "Next": "Volgende",
    "Done": "Klaar",
    "Others": "Andere",
    "Thanks for installing Tally! I hope it helps you manage your work. It is designed to be a very, very simple app. For any feedback or extra features, contact me at:": "Bedankt voor het installeren van Tally! Ik hoop dat het je helpt je werk te beheren. Het is bedoeld als een heel, heel simpele app. Voor feedback of extra functies kun je me bereiken op:"
]

private let translationsFR: [String: String] = [
    "Your log file could not be read. A copy was kept in the data folder.": "Impossible de lire ton fichier de journal. Une copie a été conservée dans le dossier de données.",
    "Your last session was closed at %@ because the app restarted. You can edit it in the Log.": "Ta dernière session a été fermée à %@ car l'app a redémarré. Tu peux la modifier dans le Journal.",
    "Stopped %@ at %@ when your Mac went to sleep.": "%@ s'est arrêté à %@ quand ton Mac est passé en veille.",
    "Could not change the open at login setting: %@": "Impossible de modifier l'ouverture à la connexion : %@",
    "Open Tally": "Ouvrir Tally",
    "Clock out of %@": "Arrêter %@",
    "Clock in": "Démarrer",
    "Clock in to %@": "Démarrer %@",
    "Give the project a name.": "Donne un nom au projet.",
    "You already have a project called %@.": "Tu as déjà un projet nommé %@.",
    "That is the limit: 12 projects.": "C'est la limite : 12 projets.",
    "The key %@ is already used by %@.": "La touche %@ est déjà utilisée par %@.",
    "Control+W is reserved for choosing a project. Pick another key.": "Control+W est réservé au choix d'un projet. Choisis une autre touche.",
    "That key cannot be used as a shortcut.": "Cette touche ne peut pas servir de raccourci.",
    "Project name": "Nom du projet",
    "%@ today": "%@ aujourd'hui",
    "What are you starting?": "Tu démarres quoi ?",
    "Press a key to start. Esc to cancel.": "Appuie sur une touche pour démarrer. Échap pour annuler.",
    "Track": "Suivi",
    "Stats": "Stats",
    "Log": "Journal",
    "Projects": "Projets",
    "Quit Tally": "Quitter Tally",
    "TRACKING %@": "SUIVI : %@",
    "since %@": "depuis %@",
    "READY": "PRÊT",
    "Add a project to start": "Ajoute un projet pour démarrer",
    "Pick a project to start": "Choisis un projet pour démarrer",
    "Add your first project": "Ajoute ton premier projet",
    "Clock out": "Arrêter",
    "Switch": "Changer",
    "choose": "choisir",
    "New project": "Nouveau projet",
    "Today": "Aujourd'hui",
    "This week": "Cette semaine",
    "This month": "Ce mois-ci",
    "This year": "Cette année",
    "All": "Tout",
    "Last 7 days": "7 derniers jours",
    "Averages": "Moyennes",
    "Per day": "Par jour",
    "Per week": "Par semaine",
    "Per month": "Par mois",
    "Per day only counts days you worked. Weeks and months count from your first log.": "Par jour ne compte que les jours travaillés. Les semaines et les mois comptent depuis ta première entrée.",
    "Nothing logged yet.": "Rien d'enregistré pour l'instant.",
    "Add time": "Ajouter du temps",
    "Edit time": "Modifier le temps",
    "Export CSV": "Exporter en CSV",
    "%@ to %@": "%@ à %@",
    "now": "maintenant",
    "Start": "Début",
    "End": "Fin",
    "Still running. Clock out to set the end time.": "Toujours en cours. Arrête le chrono pour fixer l'heure de fin.",
    "Total: %@": "Total : %@",
    "End must be after start.": "La fin doit être après le début.",
    "Note (optional)": "Note (facultatif)",
    "Delete": "Supprimer",
    "Cancel": "Annuler",
    "Save": "Enregistrer",
    "No projects yet. Add one to start tracking.": "Pas encore de projets. Ajoutes-en un pour commencer.",
    "Archived": "Archivés",
    "Restore": "Restaurer",
    "Hours of archived projects stay in your Log and Stats.": "Les heures des projets archivés restent dans ton Journal et tes Stats.",
    "Settings": "Réglages",
    "Use Touch ID": "Utiliser Touch ID",
    "Off: no fingerprint is asked. Use this if your Mac has no Touch ID.": "Désactivé : aucune empreinte demandée. Utile si ton Mac n'a pas Touch ID.",
    "Language": "Langue",
    "Shortcuts": "Raccourcis",
    "Made by Gil": "Créé par Gil",
    "Feedback or feature suggestions:": "Retours ou idées de fonctionnalités :",
    "Clock out, or choose what to start": "Arrêter, ou choisir quoi démarrer",
    "Show quick instructions": "Afficher les instructions rapides",
    "Totals": "Totaux",
    "Your data": "Vos données",
    "Back up": "Sauvegarder",
    "Import": "Importer",
    "Move your hours to a new Mac, or restore them after a reinstall.": "Déplacez vos heures vers un nouveau Mac, ou restaurez-les après une réinstallation.",
    "Backup saved.": "Sauvegarde enregistrée.",
    "Choose a Tally backup file, or a data folder.": "Choisissez un fichier de sauvegarde Tally ou un dossier de données.",
    "That does not look like Tally data.": "Ceci ne ressemble pas à des données Tally.",
    "Replace your current data?": "Remplacer vos données actuelles ?",
    "Import %d sessions? A safety copy of your current data stays in the data folder.": "Importer %d sessions ? Une copie de sécurité de vos données actuelles reste dans le dossier de données.",
    "Imported %d sessions.": "%d sessions importées.",
    "Open at login": "Ouvrir à la connexion",
    "To turn this on, put Tally in your Applications folder and open it from there.": "Pour l'activer, place Tally dans ton dossier Applications et ouvre-le depuis là.",
    "macOS needs your OK in System Settings > General > Login Items.": "macOS a besoin de ton accord dans Réglages Système > Général > Ouverture.",
    "Edit project": "Modifier le projet",
    "Name": "Nom",
    "For example: Writing, Client work, Gym": "Par exemple : Écriture, Clients, Sport",
    "Colour": "Couleur",
    "Or a custom colour": "Ou une couleur personnalisée",
    "Logo or photo (optional)": "Logo ou photo (facultatif)",
    "Choose image…": "Choisir une image…",
    "Remove": "Retirer",
    "It shows on the card. Wide logos and square photos both work.": "Il s'affiche sur la carte. Les logos larges et les photos carrées fonctionnent.",
    "Shortcut": "Raccourci",
    "Starts and stops this project from anywhere. Control + W is always \"choose\".": "Démarre et arrête ce projet de n'importe où. Control + W sert toujours à « choisir ».",
    "Delete this project…": "Supprimer ce projet…",
    "%@ is logged on this project. It stays in your Log and Stats, and the project moves to Archived, where you can restore it any time.": "%@ sont enregistrées sur ce projet. Elles restent dans ton Journal et tes Stats, et le projet passe dans Archivés, où tu peux le restaurer à tout moment.",
    "Nothing is logged on this project, so it will be removed.": "Rien n'est enregistré sur ce projet, il sera donc supprimé.",
    "This project is running. Clock out first.": "Ce projet est en cours. Arrête-le d'abord.",
    "Type \"%@\" to confirm": "Tape « %@ » pour confirmer",
    "Keep project": "Garder le projet",
    "Delete project": "Supprimer le projet",
    "Welcome to Tally": "Bienvenue sur Tally",
    "Click this icon in your menu bar": "Clique sur cette icône dans ta barre des menus",
    "This is where Tally lives. Choose your language, then start the quick instructions.": "C'est ici que vit Tally. Choisis ta langue, puis lance les instructions rapides.",
    "Start quick instructions": "Lancer les instructions rapides",
    "Add a project": "Ajoute un projet",
    "This is where you add and edit projects. We will create one together at the end.": "Ici tu ajoutes et modifies tes projets. À la fin, on en crée un ensemble.",
    "Tally opens at login. Press Control + W any time to start. Want to practise? We can create a project together, step by step.": "Tally s'ouvre à la connexion. Appuie sur Control + W à tout moment pour démarrer. Envie de t'entraîner ? On peut créer un projet ensemble, pas à pas.",
    "Let's make your first one together, step by step.": "Créons ton premier ensemble, pas à pas.",
    "Create a project": "Créer un projet",
    "Name it": "Donne-lui un nom",
    "Type a name for your project, for example Writing or Client work. Then tap Next.": "Saisis un nom pour ton projet, par exemple Écriture ou Clients. Puis appuie sur Suivant.",
    "Pick a colour": "Choisis une couleur",
    "Choose a colour for the card. The preview at the top changes as you go.": "Choisis une couleur pour la carte. L'aperçu en haut change au fur et à mesure.",
    "Add a logo or photo": "Ajoute un logo ou une photo",
    "Optional. Tap Choose image to use a logo or a photo, or just tap Next to skip.": "Facultatif. Appuie sur Choisir une image pour un logo ou une photo, ou sur Suivant pour passer.",
    "Your shortcut": "Ton raccourci",
    "This key is suggested from the name. Press Control + this key anywhere to clock in or out. You can change it.": "Cette touche est suggérée d'après le nom. Appuie sur Control + cette touche n'importe où pour démarrer ou arrêter. Tu peux la changer.",
    "Save it": "Enregistre-le",
    "Tap Save. Your project appears on the Track tab, ready to use.": "Appuie sur Enregistrer. Ton projet apparaît dans l'onglet Suivi, prêt à l'emploi.",
    "Got it": "Compris",
    "Your settings": "Tes réglages",
    "Turn Touch ID on or off, change the language and choose if Tally opens at login.": "Active ou désactive Touch ID, change la langue et choisis si Tally s'ouvre à la connexion.",
    "Clock in and out": "Démarrer et arrêter",
    "Tap a project to clock in. Tap it again to clock out. Or press Control + its key from anywhere. Control + W lets you choose.": "Appuie sur un projet pour démarrer. Appuie encore pour arrêter. Ou utilise Control + sa touche, de n'importe où. Control + W te laisse choisir.",
    "See your hours": "Vois tes heures",
    "Stats shows totals and averages for each project.": "Stats affiche les totaux et moyennes de chaque projet.",
    "Fix your log": "Corrige ton journal",
    "Log lets you edit or add time by hand. Going to sleep stops the clock for you.": "Le Journal te permet de modifier ou d'ajouter du temps à la main. La mise en veille arrête le chrono pour toi.",
    "You're all set": "Tout est prêt",
    "Create your first project": "Crée ton premier projet",
    "Create first project": "Créer le premier projet",
    "Skip": "Passer",
    "Back": "Retour",
    "Next": "Suivant",
    "Done": "Terminé",
    "Others": "Autres",
    "Thanks for installing Tally! I hope it helps you manage your work. It is designed to be a very, very simple app. For any feedback or extra features, contact me at:": "Merci d'avoir installé Tally ! J'espère que cela t'aidera à gérer ton travail. C'est une app pensée pour être très, très simple. Pour tout retour ou fonctionnalité en plus, écris-moi à :"
]

private let translationsDE: [String: String] = [
    "Your log file could not be read. A copy was kept in the data folder.": "Deine Protokolldatei konnte nicht gelesen werden. Eine Kopie wurde im Datenordner gespeichert.",
    "Your last session was closed at %@ because the app restarted. You can edit it in the Log.": "Deine letzte Sitzung wurde um %@ beendet, weil die App neu gestartet wurde. Du kannst sie im Protokoll bearbeiten.",
    "Stopped %@ at %@ when your Mac went to sleep.": "%@ wurde um %@ gestoppt, als dein Mac in den Ruhezustand ging.",
    "Could not change the open at login setting: %@": "Die Einstellung zum Öffnen bei der Anmeldung konnte nicht geändert werden: %@",
    "Open Tally": "Tally öffnen",
    "Clock out of %@": "%@ stoppen",
    "Clock in": "Starten",
    "Clock in to %@": "%@ starten",
    "Give the project a name.": "Gib dem Projekt einen Namen.",
    "You already have a project called %@.": "Du hast bereits ein Projekt namens %@.",
    "That is the limit: 12 projects.": "Das ist das Limit: 12 Projekte.",
    "The key %@ is already used by %@.": "Die Taste %@ wird bereits von %@ verwendet.",
    "Control+W is reserved for choosing a project. Pick another key.": "Control+W ist für die Projektauswahl reserviert. Wähle eine andere Taste.",
    "That key cannot be used as a shortcut.": "Diese Taste kann nicht als Kurzbefehl verwendet werden.",
    "Project name": "Projektname",
    "%@ today": "%@ heute",
    "What are you starting?": "Womit startest du?",
    "Press a key to start. Esc to cancel.": "Drücke eine Taste zum Starten. Esc zum Abbrechen.",
    "Track": "Zeit",
    "Stats": "Statistik",
    "Log": "Protokoll",
    "Projects": "Projekte",
    "Quit Tally": "Tally beenden",
    "TRACKING %@": "LÄUFT: %@",
    "since %@": "seit %@",
    "READY": "BEREIT",
    "Add a project to start": "Füge ein Projekt hinzu, um zu starten",
    "Pick a project to start": "Wähle ein Projekt zum Starten",
    "Add your first project": "Füge dein erstes Projekt hinzu",
    "Clock out": "Stoppen",
    "Switch": "Wechseln",
    "choose": "auswählen",
    "New project": "Neues Projekt",
    "Today": "Heute",
    "This week": "Diese Woche",
    "This month": "Diesen Monat",
    "This year": "Dieses Jahr",
    "All": "Alle",
    "Last 7 days": "Letzte 7 Tage",
    "Averages": "Durchschnitte",
    "Per day": "Pro Tag",
    "Per week": "Pro Woche",
    "Per month": "Pro Monat",
    "Per day only counts days you worked. Weeks and months count from your first log.": "Pro Tag zählt nur Tage, an denen du gearbeitet hast. Wochen und Monate zählen ab deinem ersten Eintrag.",
    "Nothing logged yet.": "Noch nichts erfasst.",
    "Add time": "Zeit hinzufügen",
    "Edit time": "Zeit bearbeiten",
    "Export CSV": "CSV exportieren",
    "%@ to %@": "%@ bis %@",
    "now": "jetzt",
    "Start": "Beginn",
    "End": "Ende",
    "Still running. Clock out to set the end time.": "Läuft noch. Stoppe die Uhr, um die Endzeit festzulegen.",
    "Total: %@": "Gesamt: %@",
    "End must be after start.": "Das Ende muss nach dem Beginn liegen.",
    "Note (optional)": "Notiz (optional)",
    "Delete": "Löschen",
    "Cancel": "Abbrechen",
    "Save": "Speichern",
    "No projects yet. Add one to start tracking.": "Noch keine Projekte. Füge eines hinzu, um zu starten.",
    "Archived": "Archiviert",
    "Restore": "Wiederherstellen",
    "Hours of archived projects stay in your Log and Stats.": "Die Stunden archivierter Projekte bleiben in Protokoll und Statistik.",
    "Settings": "Einstellungen",
    "Use Touch ID": "Touch ID verwenden",
    "Off: no fingerprint is asked. Use this if your Mac has no Touch ID.": "Aus: Es wird kein Fingerabdruck verlangt. Nutze das, wenn dein Mac kein Touch ID hat.",
    "Language": "Sprache",
    "Shortcuts": "Kurzbefehle",
    "Made by Gil": "Entwickelt von Gil",
    "Feedback or feature suggestions:": "Feedback oder Funktionsideen:",
    "Clock out, or choose what to start": "Stoppen oder auswählen, was du startest",
    "Show quick instructions": "Kurzanleitung anzeigen",
    "Totals": "Summen",
    "Your data": "Deine Daten",
    "Back up": "Sichern",
    "Import": "Importieren",
    "Move your hours to a new Mac, or restore them after a reinstall.": "Übertrage deine Stunden auf einen neuen Mac oder stelle sie nach einer Neuinstallation wieder her.",
    "Backup saved.": "Sicherung gespeichert.",
    "Choose a Tally backup file, or a data folder.": "Wähle eine Tally-Sicherungsdatei oder einen Datenordner.",
    "That does not look like Tally data.": "Das sieht nicht nach Tally-Daten aus.",
    "Replace your current data?": "Deine aktuellen Daten ersetzen?",
    "Import %d sessions? A safety copy of your current data stays in the data folder.": "%d Sitzungen importieren? Eine Sicherheitskopie deiner aktuellen Daten bleibt im Datenordner.",
    "Imported %d sessions.": "%d Sitzungen importiert.",
    "Open at login": "Bei Anmeldung öffnen",
    "To turn this on, put Tally in your Applications folder and open it from there.": "Lege Tally dazu in deinen Programme-Ordner und öffne es von dort.",
    "macOS needs your OK in System Settings > General > Login Items.": "macOS braucht deine Zustimmung unter Systemeinstellungen > Allgemein > Anmeldeobjekte.",
    "Edit project": "Projekt bearbeiten",
    "Name": "Name",
    "For example: Writing, Client work, Gym": "Zum Beispiel: Schreiben, Kundenarbeit, Sport",
    "Colour": "Farbe",
    "Or a custom colour": "Oder eine eigene Farbe",
    "Logo or photo (optional)": "Logo oder Foto (optional)",
    "Choose image…": "Bild wählen…",
    "Remove": "Entfernen",
    "It shows on the card. Wide logos and square photos both work.": "Es erscheint auf der Karte. Breite Logos und quadratische Fotos funktionieren beide.",
    "Shortcut": "Kurzbefehl",
    "Starts and stops this project from anywhere. Control + W is always \"choose\".": "Startet und stoppt dieses Projekt von überall. Control + W ist immer „auswählen“.",
    "Delete this project…": "Dieses Projekt löschen…",
    "%@ is logged on this project. It stays in your Log and Stats, and the project moves to Archived, where you can restore it any time.": "%@ sind für dieses Projekt erfasst. Sie bleiben in Protokoll und Statistik, und das Projekt wird archiviert. Dort kannst du es jederzeit wiederherstellen.",
    "Nothing is logged on this project, so it will be removed.": "Für dieses Projekt ist nichts erfasst, deshalb wird es gelöscht.",
    "This project is running. Clock out first.": "Dieses Projekt läuft. Stoppe es zuerst.",
    "Type \"%@\" to confirm": "Tippe „%@“ zur Bestätigung",
    "Keep project": "Projekt behalten",
    "Delete project": "Projekt löschen",
    "Welcome to Tally": "Willkommen bei Tally",
    "Click this icon in your menu bar": "Klicke auf dieses Symbol in deiner Menüleiste",
    "This is where Tally lives. Choose your language, then start the quick instructions.": "Hier lebt Tally. Wähle deine Sprache und starte die Kurzanleitung.",
    "Start quick instructions": "Kurzanleitung starten",
    "Add a project": "Füge ein Projekt hinzu",
    "This is where you add and edit projects. We will create one together at the end.": "Hier fügst du Projekte hinzu und bearbeitest sie. Am Ende erstellen wir gemeinsam eines.",
    "Tally opens at login. Press Control + W any time to start. Want to practise? We can create a project together, step by step.": "Tally öffnet sich bei der Anmeldung. Drücke jederzeit Control + W zum Starten. Willst du üben? Wir können gemeinsam Schritt für Schritt ein Projekt erstellen.",
    "Let's make your first one together, step by step.": "Lass uns gemeinsam dein erstes erstellen, Schritt für Schritt.",
    "Create a project": "Projekt erstellen",
    "Name it": "Gib ihm einen Namen",
    "Type a name for your project, for example Writing or Client work. Then tap Next.": "Gib deinem Projekt einen Namen, zum Beispiel Schreiben oder Kundenarbeit. Tippe dann auf Weiter.",
    "Pick a colour": "Wähle eine Farbe",
    "Choose a colour for the card. The preview at the top changes as you go.": "Wähle eine Farbe für die Karte. Die Vorschau oben ändert sich mit.",
    "Add a logo or photo": "Füge ein Logo oder Foto hinzu",
    "Optional. Tap Choose image to use a logo or a photo, or just tap Next to skip.": "Optional. Tippe auf Bild wählen für ein Logo oder Foto, oder auf Weiter zum Überspringen.",
    "Your shortcut": "Dein Kurzbefehl",
    "This key is suggested from the name. Press Control + this key anywhere to clock in or out. You can change it.": "Diese Taste wird aus dem Namen vorgeschlagen. Drücke überall Control + diese Taste zum Starten oder Stoppen. Du kannst sie ändern.",
    "Save it": "Speichere es",
    "Tap Save. Your project appears on the Track tab, ready to use.": "Tippe auf Speichern. Dein Projekt erscheint im Tab Zeit, bereit zur Nutzung.",
    "Got it": "Verstanden",
    "Your settings": "Deine Einstellungen",
    "Turn Touch ID on or off, change the language and choose if Tally opens at login.": "Schalte Touch ID ein oder aus, ändere die Sprache und wähle, ob Tally bei der Anmeldung öffnet.",
    "Clock in and out": "Ein- und ausstempeln",
    "Tap a project to clock in. Tap it again to clock out. Or press Control + its key from anywhere. Control + W lets you choose.": "Tippe auf ein Projekt zum Starten. Tippe erneut zum Stoppen. Oder drücke überall Control + seine Taste. Mit Control + W wählst du aus.",
    "See your hours": "Sieh deine Stunden",
    "Stats shows totals and averages for each project.": "Statistik zeigt Summen und Durchschnitte je Projekt.",
    "Fix your log": "Korrigiere dein Protokoll",
    "Log lets you edit or add time by hand. Going to sleep stops the clock for you.": "Im Protokoll kannst du Zeit von Hand bearbeiten oder hinzufügen. Im Ruhezustand stoppt die Uhr von selbst.",
    "You're all set": "Alles bereit",
    "Create your first project": "Erstelle dein erstes Projekt",
    "Create first project": "Erstes Projekt erstellen",
    "Skip": "Überspringen",
    "Back": "Zurück",
    "Next": "Weiter",
    "Done": "Fertig",
    "Others": "Andere",
    "Thanks for installing Tally! I hope it helps you manage your work. It is designed to be a very, very simple app. For any feedback or extra features, contact me at:": "Danke, dass du Tally installiert hast! Ich hoffe, es hilft dir, deine Arbeit zu organisieren. Es soll eine sehr, sehr einfache App sein. Für Feedback oder zusätzliche Funktionen erreichst du mich unter:"
]

private let translationsIT: [String: String] = [
    "Your log file could not be read. A copy was kept in the data folder.": "Impossibile leggere il file del registro. Una copia è stata conservata nella cartella dei dati.",
    "Your last session was closed at %@ because the app restarted. You can edit it in the Log.": "La tua ultima sessione è stata chiusa alle %@ perché l'app si è riavviata. Puoi modificarla nel Registro.",
    "Stopped %@ at %@ when your Mac went to sleep.": "%@ si è fermato alle %@ quando il Mac è andato in stop.",
    "Could not change the open at login setting: %@": "Impossibile modificare l'apertura all'accesso: %@",
    "Open Tally": "Apri Tally",
    "Clock out of %@": "Ferma %@",
    "Clock in": "Avvia",
    "Clock in to %@": "Avvia %@",
    "Give the project a name.": "Dai un nome al progetto.",
    "You already have a project called %@.": "Hai già un progetto chiamato %@.",
    "That is the limit: 12 projects.": "Questo è il limite: 12 progetti.",
    "The key %@ is already used by %@.": "Il tasto %@ è già usato da %@.",
    "Control+W is reserved for choosing a project. Pick another key.": "Control+W è riservato alla scelta di un progetto. Scegli un altro tasto.",
    "That key cannot be used as a shortcut.": "Questo tasto non può essere usato come scorciatoia.",
    "Project name": "Nome del progetto",
    "%@ today": "%@ oggi",
    "What are you starting?": "Cosa stai iniziando?",
    "Press a key to start. Esc to cancel.": "Premi un tasto per iniziare. Esc per annullare.",
    "Track": "Tempo",
    "Stats": "Statistiche",
    "Log": "Registro",
    "Projects": "Progetti",
    "Quit Tally": "Esci da Tally",
    "TRACKING %@": "TRACCIO %@",
    "since %@": "dalle %@",
    "READY": "PRONTO",
    "Add a project to start": "Aggiungi un progetto per iniziare",
    "Pick a project to start": "Scegli un progetto per iniziare",
    "Add your first project": "Aggiungi il tuo primo progetto",
    "Clock out": "Ferma",
    "Switch": "Cambia",
    "choose": "scegliere",
    "New project": "Nuovo progetto",
    "Today": "Oggi",
    "This week": "Questa settimana",
    "This month": "Questo mese",
    "This year": "Quest'anno",
    "All": "Tutto",
    "Last 7 days": "Ultimi 7 giorni",
    "Averages": "Medie",
    "Per day": "Al giorno",
    "Per week": "A settimana",
    "Per month": "Al mese",
    "Per day only counts days you worked. Weeks and months count from your first log.": "Al giorno conta solo i giorni in cui hai lavorato. Settimane e mesi contano dalla tua prima registrazione.",
    "Nothing logged yet.": "Ancora nulla registrato.",
    "Add time": "Aggiungi tempo",
    "Edit time": "Modifica tempo",
    "Export CSV": "Esporta CSV",
    "%@ to %@": "da %@ a %@",
    "now": "adesso",
    "Start": "Inizio",
    "End": "Fine",
    "Still running. Clock out to set the end time.": "Ancora in corso. Ferma il timer per impostare l'ora di fine.",
    "Total: %@": "Totale: %@",
    "End must be after start.": "La fine deve essere dopo l'inizio.",
    "Note (optional)": "Nota (facoltativa)",
    "Delete": "Elimina",
    "Cancel": "Annulla",
    "Save": "Salva",
    "No projects yet. Add one to start tracking.": "Ancora nessun progetto. Aggiungine uno per iniziare.",
    "Archived": "Archiviati",
    "Restore": "Ripristina",
    "Hours of archived projects stay in your Log and Stats.": "Le ore dei progetti archiviati restano nel Registro e nelle Statistiche.",
    "Settings": "Impostazioni",
    "Use Touch ID": "Usa Touch ID",
    "Off: no fingerprint is asked. Use this if your Mac has no Touch ID.": "Disattivato: non viene chiesta l'impronta. Usalo se il tuo Mac non ha Touch ID.",
    "Language": "Lingua",
    "Shortcuts": "Scorciatoie",
    "Made by Gil": "Creato da Gil",
    "Feedback or feature suggestions:": "Feedback o idee per nuove funzioni:",
    "Clock out, or choose what to start": "Ferma, o scegli cosa avviare",
    "Show quick instructions": "Mostra le istruzioni rapide",
    "Totals": "Totali",
    "Your data": "I tuoi dati",
    "Back up": "Esegui backup",
    "Import": "Importa",
    "Move your hours to a new Mac, or restore them after a reinstall.": "Sposta le tue ore su un nuovo Mac, o ripristinale dopo una reinstallazione.",
    "Backup saved.": "Backup salvato.",
    "Choose a Tally backup file, or a data folder.": "Scegli un file di backup di Tally o una cartella dati.",
    "That does not look like Tally data.": "Questi non sembrano dati di Tally.",
    "Replace your current data?": "Sostituire i dati attuali?",
    "Import %d sessions? A safety copy of your current data stays in the data folder.": "Importare %d sessioni? Una copia di sicurezza dei dati attuali resta nella cartella dati.",
    "Imported %d sessions.": "%d sessioni importate.",
    "Open at login": "Apri all'accesso",
    "To turn this on, put Tally in your Applications folder and open it from there.": "Per attivarlo, metti Tally nella cartella Applicazioni e aprilo da lì.",
    "macOS needs your OK in System Settings > General > Login Items.": "macOS ha bisogno del tuo consenso in Impostazioni di Sistema > Generali > Elementi login.",
    "Edit project": "Modifica progetto",
    "Name": "Nome",
    "For example: Writing, Client work, Gym": "Per esempio: Scrittura, Clienti, Palestra",
    "Colour": "Colore",
    "Or a custom colour": "Oppure un colore personalizzato",
    "Logo or photo (optional)": "Logo o foto (facoltativo)",
    "Choose image…": "Scegli immagine…",
    "Remove": "Rimuovi",
    "It shows on the card. Wide logos and square photos both work.": "Appare sulla scheda. Funzionano sia logo larghi sia foto quadrate.",
    "Shortcut": "Scorciatoia",
    "Starts and stops this project from anywhere. Control + W is always \"choose\".": "Avvia e ferma questo progetto da qualsiasi punto. Control + W serve sempre a «scegliere».",
    "Delete this project…": "Elimina questo progetto…",
    "%@ is logged on this project. It stays in your Log and Stats, and the project moves to Archived, where you can restore it any time.": "%@ registrate su questo progetto. Restano nel Registro e nelle Statistiche, e il progetto passa in Archiviati, dove puoi ripristinarlo quando vuoi.",
    "Nothing is logged on this project, so it will be removed.": "Su questo progetto non c'è nulla di registrato, quindi verrà rimosso.",
    "This project is running. Clock out first.": "Questo progetto è in corso. Fermalo prima.",
    "Type \"%@\" to confirm": "Scrivi «%@» per confermare",
    "Keep project": "Tieni il progetto",
    "Delete project": "Elimina progetto",
    "Welcome to Tally": "Benvenuto in Tally",
    "Click this icon in your menu bar": "Clicca su questa icona nella barra dei menu",
    "This is where Tally lives. Choose your language, then start the quick instructions.": "Qui vive Tally. Scegli la lingua, poi avvia le istruzioni rapide.",
    "Start quick instructions": "Avvia le istruzioni rapide",
    "Add a project": "Aggiungi un progetto",
    "This is where you add and edit projects. We will create one together at the end.": "Qui aggiungi e modifichi i progetti. Alla fine ne creeremo uno insieme.",
    "Tally opens at login. Press Control + W any time to start. Want to practise? We can create a project together, step by step.": "Tally si apre all'accesso. Premi Control + W in qualsiasi momento per iniziare. Vuoi esercitarti? Possiamo creare un progetto insieme, passo dopo passo.",
    "Let's make your first one together, step by step.": "Creiamo insieme il tuo primo, passo dopo passo.",
    "Create a project": "Crea un progetto",
    "Name it": "Dagli un nome",
    "Type a name for your project, for example Writing or Client work. Then tap Next.": "Scrivi un nome per il progetto, per esempio Scrittura o Clienti. Poi tocca Avanti.",
    "Pick a colour": "Scegli un colore",
    "Choose a colour for the card. The preview at the top changes as you go.": "Scegli un colore per la scheda. L'anteprima in alto cambia man mano.",
    "Add a logo or photo": "Aggiungi un logo o una foto",
    "Optional. Tap Choose image to use a logo or a photo, or just tap Next to skip.": "Facoltativo. Tocca Scegli immagine per un logo o una foto, oppure Avanti per saltare.",
    "Your shortcut": "La tua scorciatoia",
    "This key is suggested from the name. Press Control + this key anywhere to clock in or out. You can change it.": "Questo tasto è suggerito dal nome. Premi Control + questo tasto ovunque per avviare o fermare. Puoi cambiarlo.",
    "Save it": "Salvalo",
    "Tap Save. Your project appears on the Track tab, ready to use.": "Tocca Salva. Il progetto appare nella scheda Tempo, pronto all'uso.",
    "Got it": "Capito",
    "Your settings": "Le tue impostazioni",
    "Turn Touch ID on or off, change the language and choose if Tally opens at login.": "Attiva o disattiva Touch ID, cambia la lingua e scegli se Tally si apre all'accesso.",
    "Clock in and out": "Avviare e fermare",
    "Tap a project to clock in. Tap it again to clock out. Or press Control + its key from anywhere. Control + W lets you choose.": "Tocca un progetto per avviare. Toccalo di nuovo per fermare. Oppure premi Control + il suo tasto, ovunque. Con Control + W scegli.",
    "See your hours": "Guarda le tue ore",
    "Stats shows totals and averages for each project.": "Statistiche mostra totali e medie per ogni progetto.",
    "Fix your log": "Correggi il registro",
    "Log lets you edit or add time by hand. Going to sleep stops the clock for you.": "Nel Registro puoi modificare o aggiungere tempo a mano. Quando il Mac va in stop, il timer si ferma da solo.",
    "You're all set": "Tutto pronto",
    "Create your first project": "Crea il tuo primo progetto",
    "Create first project": "Crea il primo progetto",
    "Skip": "Salta",
    "Back": "Indietro",
    "Next": "Avanti",
    "Done": "Fatto",
    "Others": "Altre",
    "Thanks for installing Tally! I hope it helps you manage your work. It is designed to be a very, very simple app. For any feedback or extra features, contact me at:": "Grazie per aver installato Tally! Spero ti aiuti a gestire il tuo lavoro. È pensata per essere un'app molto, molto semplice. Per feedback o funzioni extra, scrivimi a:"
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

    // Backup and import

    private struct BackupFile: Codable {
        var projects: [ProjectDef]
        var sessions: [Session]
    }

    /// Saves projects and hours into one file you can keep or move to another Mac.
    func exportBackup() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "tally-backup.json"
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let dest = panel.url else { return }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(BackupFile(projects: projects, sessions: sessions)) {
            try? data.write(to: dest, options: .atomic)
            note = T("Backup saved.")
        }
    }

    /// Reads a Tally backup file, or an old data folder, and replaces the current data with it.
    func importData() {
        let open = NSOpenPanel()
        open.canChooseFiles = true
        open.canChooseDirectories = true
        open.allowsMultipleSelection = false
        open.message = T("Choose a Tally backup file, or a data folder.")
        NSApp.activate(ignoringOtherApps: true)
        guard open.runModal() == .OK, let url = open.url else { return }

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        var newProjects: [ProjectDef]? = nil
        var newSessions: [Session]? = nil
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        // A folder, or one of the files inside an old data folder, both work.
        let folder = isDir.boolValue ? url : url.deletingLastPathComponent()
        if !isDir.boolValue, let d = try? Data(contentsOf: url), let b = try? dec.decode(BackupFile.self, from: d) {
            newProjects = b.projects
            newSessions = b.sessions
        } else {
            if let d = try? Data(contentsOf: folder.appendingPathComponent("sessions.json")) {
                newSessions = try? dec.decode([Session].self, from: d)
            }
            if let d = try? Data(contentsOf: folder.appendingPathComponent("projects.json")) {
                newProjects = try? dec.decode([ProjectDef].self, from: d)
            }
        }
        guard let incoming = newSessions else {
            note = T("That does not look like Tally data.")
            return
        }

        let alert = NSAlert()
        alert.messageText = T("Replace your current data?")
        alert.informativeText = T("Import %d sessions? A safety copy of your current data stays in the data folder.", incoming.count)
        alert.addButton(withTitle: T("Import"))
        alert.addButton(withTitle: T("Cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        // Safety copy first.
        let fm = FileManager.default
        let before1 = dir.appendingPathComponent("sessions.before-import.json")
        let before2 = dir.appendingPathComponent("projects.before-import.json")
        try? fm.removeItem(at: before1)
        try? fm.removeItem(at: before2)
        try? fm.copyItem(at: sessionsURL, to: before1)
        try? fm.copyItem(at: projectsURL, to: before2)

        sessions = incoming
        if let p = newProjects, !p.isEmpty { projects = p }
        let known = Set(projects.map(\.id))
        for id in Set(sessions.map(\.project)).sorted() where !known.contains(id) {
            projects.append(ProjectDef.placeholder(id: id))
        }
        save()
        saveProjects()
        note = T("Imported %d sessions.", incoming.count)
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
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Tally"
        w.contentView = NSHostingView(rootView: view)
        w.isReleasedWhenClosed = false
        if let f = NSScreen.main?.visibleFrame {
            w.setFrameTopLeftPoint(NSPoint(x: f.maxX - 440 - 24, y: f.maxY - 12))
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
    @State private var showAverages = false

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

                Picker("", selection: $showAverages) {
                    Text(T("Totals")).tag(false)
                    Text(T("Averages")).tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if showAverages {
                    HStack(spacing: 10) {
                        StatCard(title: T("Per day"), value: hm(avg.day))
                        StatCard(title: T("Per week"), value: hm(avg.week))
                        StatCard(title: T("Per month"), value: hm(avg.month))
                    }
                    Text(T("Per day only counts days you worked. Weeks and months count from your first log."))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(periods, id: \.0) { p in
                            StatCard(title: p.0, value: hm(store.seconds(filter, from: p.1.start, to: p.1.end)))
                        }
                    }
                }
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
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
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
        let title = cal.isDateInToday(day)
            ? T("Today")
            : day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(Loc.current.locale))

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(hm(total))
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)

            ForEach(Array(list.enumerated()), id: \.element.id) { i, s in
                if i > 0 { Divider().opacity(0.5).padding(.leading, 30) }
                Button {
                    editing = Draft(id: s.id, project: s.project, start: s.start,
                                    end: s.end ?? Date(), running: s.end == nil, isNew: false,
                                    note: s.note ?? "")
                } label: {
                    HStack(spacing: 10) {
                        ProjectBadge(p: store.def(s.project), size: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(store.name(s.project)).lineLimit(1)
                            Text(T("%@ to %@", shortTime(s.start), s.end.map(shortTime) ?? T("now")))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let n = s.note, !n.isEmpty {
                                Text(n).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
                            }
                        }
                        Spacer()
                        Text(hm(s.duration(at: store.now)))
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
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
                        LanguagePicker()
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text(T("Your data")).font(.callout)
                        HStack(spacing: 8) {
                            Button(T("Back up")) { store.exportBackup() }
                            Button(T("Import")) { store.importData() }
                            Button(T("Export CSV")) { store.exportCSV() }
                        }
                        .controlSize(.small)
                        note(T("Move your hours to a new Mac, or restore them after a reinstall."))
                    }
                    .padding(.top, 10)
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
                    Text(T("Made by Gil"))
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

/// First start only: thanks the user, lets them pick a language, then starts the tour.
struct OnboardingView: View {
    @EnvironmentObject var store: Store
    var start: () -> Void
    @State private var shown = false

    var body: some View {
        VStack(spacing: 12) {
            AnimatedClock()
                .padding(.top, 4)
            Text(T("Welcome to Tally"))
                .font(.system(.title, design: .rounded, weight: .bold))
            Text(T("Thanks for installing Tally! I hope it helps you manage your work. It is designed to be a very, very simple app. For any feedback or extra features, contact me at:"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Link("pupal08.ribbons@icloud.com", destination: URL(string: "mailto:pupal08.ribbons@icloud.com")!)
                .font(.callout)
            Text("Gil")
                .font(.system(.callout, design: .rounded, weight: .semibold))
            Divider().padding(.vertical, 4)
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 20, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.primary.opacity(0.1)))
                Text(T("Click this icon in your menu bar"))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            Text(T("This is where Tally lives. Choose your language, then start the quick instructions."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            LanguagePicker()
            Spacer(minLength: 0)
            Button(T("Start quick instructions")) { start() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(24)
        .frame(width: 440, height: 600)
        .opacity(shown ? 1 : 0)
        .offset(y: shown ? 0 : 12)
        .onAppear { withAnimation(.easeOut(duration: 0.7)) { shown = true } }
    }
}

/// A small clock whose hands keep moving. Pure SwiftUI, no images.
struct AnimatedClock: View {
    private func hand(_ length: CGFloat, _ width: CGFloat, _ angle: Double) -> some View {
        Capsule()
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let pulse = (sin(t * 2.2) + 1) / 2
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.35 * (1 - pulse)), lineWidth: 2)
                    .scaleEffect(1 + 0.4 * pulse)
                Circle().fill(Color.primary.opacity(0.07))
                Circle().stroke(Color.primary.opacity(0.3), lineWidth: 3)
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 2, height: i % 3 == 0 ? 8 : 4)
                        .offset(y: -30)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                hand(20, 3, t * 3).foregroundStyle(Color.primary)
                hand(28, 2, t * 36).foregroundStyle(Color.accentColor)
                Circle().fill(Color.accentColor).frame(width: 7, height: 7)
            }
            .frame(width: 72, height: 72)
        }
        .frame(width: 96, height: 90)
    }
}

/// English, Português, Español and an Others menu with more languages.
struct LanguagePicker: View {
    @EnvironmentObject var store: Store

    private enum LangGroup: Hashable { case en, pt, es, others }

    private var group: Binding<LangGroup> {
        Binding(
            get: {
                switch store.language {
                case .en: return .en
                case .pt: return .pt
                case .es: return .es
                default: return .others
                }
            },
            set: { g in
                switch g {
                case .en: store.language = .en
                case .pt: store.language = .pt
                case .es: store.language = .es
                case .others:
                    if !AppLang.others.contains(store.language) { store.language = .nl }
                }
            })
    }

    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: group) {
                Text("English").tag(LangGroup.en)
                Text("Português").tag(LangGroup.pt)
                Text("Español").tag(LangGroup.es)
                Text(T("Others")).tag(LangGroup.others)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if AppLang.others.contains(store.language) {
                Picker("", selection: $store.language) {
                    ForEach(AppLang.others) { l in Text(l.label).tag(l) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
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
