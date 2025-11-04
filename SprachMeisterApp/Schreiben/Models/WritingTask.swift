//
//  WritingTask.swift
//  SprachMeister
//
//  Writing task model for Goethe B1 Schreiben (Teil 1 & 2)
//  Created on 23.10.2025
//

import Foundation

/// Type of writing task
enum WritingTaskType: String, Codable, CaseIterable, Identifiable {
    case forumPost = "Teil 1: Forumsbeitrag"
    case email = "Teil 2: E-Mail"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .forumPost:
            return "Schreiben Sie einen Beitrag in einem Internetforum (ca. 150 Wörter)"
        case .email:
            return "Schreiben Sie eine E-Mail (mindestens 100 Wörter)"
        }
    }

    var icon: String {
        switch self {
        case .forumPost:
            return "text.bubble"
        case .email:
            return "envelope"
        }
    }

    var defaultTimeLimitMinutes: Int {
        switch self {
        case .forumPost: return 50
        case .email: return 25
        }
    }

    var minWords: Int {
        switch self {
        case .forumPost: return 130
        case .email: return 80
        }
    }

    var maxWords: Int {
        switch self {
        case .forumPost: return 170
        case .email: return 200
        }
    }

    var recommendedWords: Int {
        switch self {
        case .forumPost: return 150
        case .email: return 120
        }
    }
}

/// Writing task configuration
struct WritingTask: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let type: WritingTaskType
    let topic: String
    let situation: String
    let subpoints: [String] // Required points to address
    let hints: [String]? // Optional hints/suggestions
    let timeLimitMinutes: Int

    init(
        id: UUID = UUID(),
        type: WritingTaskType,
        topic: String,
        situation: String,
        subpoints: [String],
        hints: [String]? = nil,
        timeLimitMinutes: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.topic = topic
        self.situation = situation
        self.subpoints = subpoints
        self.hints = hints
        self.timeLimitMinutes = timeLimitMinutes ?? type.defaultTimeLimitMinutes
    }

    // Custom decoding to handle string IDs from JSON
    enum CodingKeys: String, CodingKey {
        case id, type, topic, situation, subpoints, hints, timeLimitMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode id as UUID string, otherwise generate from hash
        let stringId = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: stringId) {
            self.id = uuid
        } else {
            // Generate deterministic UUID from string hash
            let hash = stringId.hash
            let uuidString = String(format: "%08x-0000-0000-0000-%08x0000", abs(hash), abs(hash))
            self.id = UUID(uuidString: uuidString) ?? UUID()
        }

        self.type = try container.decode(WritingTaskType.self, forKey: .type)
        self.topic = try container.decode(String.self, forKey: .topic)
        self.situation = try container.decode(String.self, forKey: .situation)
        self.subpoints = try container.decode([String].self, forKey: .subpoints)
        self.hints = try? container.decode([String].self, forKey: .hints)
        self.timeLimitMinutes = (try? container.decode(Int.self, forKey: .timeLimitMinutes)) ?? type.defaultTimeLimitMinutes
    }

    var formattedSubpoints: String {
        subpoints.enumerated().map { "• \($0.element)" }.joined(separator: "\n")
    }
}

// MARK: - Seed Data Loader
extension WritingTask {
    /// Load tasks - returns embedded tasks (always available offline)
    static func loadTasks() -> [WritingTask] {
        return allEmbeddedTasks
    }

    /// All embedded tasks (no external files needed)
    private static let allEmbeddedTasks: [WritingTask] = teil1Tasks + teil2Tasks

    // MARK: - Teil 1: Forum Posts (15 tasks)
    private static let teil1Tasks: [WritingTask] = [
        WritingTask(type: .forumPost, topic: "Hausaufgaben in der Schule", situation: "Sie lesen in einem Forum die Frage: 'Sind Hausaufgaben wichtig oder sollten sie abgeschafft werden?'", subpoints: ["Wie war das bei Ihnen früher mit Hausaufgaben?", "Was sind Vorteile und Nachteile von Hausaufgaben?", "Wie ist die Situation in Ihrem Heimatland?", "Was meinen Sie: Sind Hausaufgaben sinnvoll?"]),
        WritingTask(type: .forumPost, topic: "Öffentliche Verkehrsmittel oder Auto?", situation: "In einem Forum diskutiert man über das Thema 'Öffentliche Verkehrsmittel vs. eigenes Auto'.", subpoints: ["Wie fahren Sie meistens zur Arbeit/Schule?", "Was sind die Vorteile von öffentlichen Verkehrsmitteln?", "Was sind die Nachteile?", "Was ist Ihre Meinung zu diesem Thema?"]),
        WritingTask(type: .forumPost, topic: "Fernsehen heute", situation: "In einem Forum wird diskutiert: 'Schauen junge Leute heute noch klassisches Fernsehen oder nur noch Streaming?'", subpoints: ["Wie war das bei Ihnen früher?", "Was sind die Vorteile von Streaming-Diensten?", "Gibt es auch Nachteile?", "Was bevorzugen Sie und warum?"]),
        WritingTask(type: .forumPost, topic: "Gesundes Essen", situation: "In einem Forum lesen Sie: 'Wie wichtig ist gesunde Ernährung im Alltag?'", subpoints: ["Wie ernähren Sie sich normalerweise?", "Was bedeutet für Sie 'gesundes Essen'?", "Ist gesunde Ernährung teuer?", "Was ist Ihre Meinung: Sollte man immer gesund essen?"]),
        WritingTask(type: .forumPost, topic: "Soziale Medien", situation: "Im Forum wird diskutiert: 'Sind soziale Medien gut oder schlecht für unsere Gesellschaft?'", subpoints: ["Nutzen Sie selbst soziale Medien? Welche?", "Was sind die Vorteile von sozialen Medien?", "Welche Probleme gibt es?", "Wie ist Ihre persönliche Meinung dazu?"]),
        WritingTask(type: .forumPost, topic: "Einkaufen: Online oder im Geschäft?", situation: "In einem Forum wird gefragt: 'Kaufen Sie lieber online oder im Geschäft ein?'", subpoints: ["Wo kaufen Sie normalerweise ein?", "Was sind die Vorteile vom Online-Shopping?", "Was spricht für das Einkaufen im Geschäft?", "Was bevorzugen Sie persönlich?"]),
        WritingTask(type: .forumPost, topic: "Fremdsprachen lernen", situation: "Im Forum diskutiert man: 'Wie wichtig ist es, Fremdsprachen zu lernen?'", subpoints: ["Welche Fremdsprachen haben Sie gelernt?", "Warum ist Fremdsprachenlernen wichtig?", "Gibt es auch Schwierigkeiten beim Sprachenlernen?", "Sollten alle Kinder mehrere Sprachen lernen?"]),
        WritingTask(type: .forumPost, topic: "Sport und Bewegung", situation: "In einem Forum lesen Sie: 'Wie wichtig ist Sport für ein gesundes Leben?'", subpoints: ["Treiben Sie regelmäßig Sport?", "Was sind die Vorteile von Sport?", "Warum treiben manche Menschen keinen Sport?", "Was ist Ihre Meinung: Braucht jeder Sport?"]),
        WritingTask(type: .forumPost, topic: "Haustiere", situation: "Im Forum wird diskutiert: 'Sollte jede Familie ein Haustier haben?'", subpoints: ["Haben Sie selbst ein Haustier?", "Was sind die Vorteile von Haustieren?", "Welche Probleme kann es geben?", "Sind Haustiere für Kinder wichtig?"]),
        WritingTask(type: .forumPost, topic: "Arbeiten von zu Hause", situation: "In einem Forum wird gefragt: 'Home-Office oder Büro - was ist besser?'", subpoints: ["Haben Sie Erfahrung mit Home-Office?", "Was sind die Vorteile von Home-Office?", "Was sind die Nachteile?", "Was bevorzugen Sie persönlich?"]),
        WritingTask(type: .forumPost, topic: "Müll und Recycling", situation: "Im Forum lesen Sie: 'Wie wichtig ist Mülltrennung und Recycling?'", subpoints: ["Wie trennen Sie Ihren Müll?", "Warum ist Recycling wichtig?", "Ist Mülltrennung schwierig?", "Was können wir noch für die Umwelt tun?"]),
        WritingTask(type: .forumPost, topic: "Lesen: Bücher oder E-Books?", situation: "In einem Forum wird diskutiert: 'Sind gedruckte Bücher oder E-Books besser?'", subpoints: ["Lesen Sie gerne? Was lesen Sie?", "Was sind die Vorteile von echten Büchern?", "Was spricht für E-Books?", "Was bevorzugen Sie und warum?"]),
        WritingTask(type: .forumPost, topic: "Urlaub und Reisen", situation: "Im Forum wird gefragt: 'Welcher Urlaub ist besser - am Strand oder in den Bergen?'", subpoints: ["Wo machen Sie normalerweise Urlaub?", "Was sind die Vorteile von Strandurlaub?", "Was spricht für Urlaub in den Bergen?", "Was ist Ihre persönliche Präferenz?"]),
        WritingTask(type: .forumPost, topic: "Mobiltelefone im Alltag", situation: "In einem Forum lesen Sie: 'Können wir noch ohne Smartphone leben?'", subpoints: ["Wie oft benutzen Sie Ihr Smartphone?", "Was sind die Vorteile von Smartphones?", "Gibt es auch Probleme mit Smartphones?", "Könnten Sie ohne Smartphone leben?"]),
        WritingTask(type: .forumPost, topic: "Kleidung und Mode", situation: "Im Forum wird diskutiert: 'Ist Mode wichtig oder nur Zeitverschwendung?'", subpoints: ["Interessieren Sie sich für Mode?", "Warum ist Mode für manche Menschen wichtig?", "Was sind die Nachteile von Mode?", "Was ist Ihre Meinung zum Thema Mode?"])
    ]

    // MARK: - Teil 2: E-Mails (15 tasks)
    private static let teil2Tasks: [WritingTask] = [
        WritingTask(type: .email, topic: "Absage für eine Veranstaltung", situation: "Sie können leider nicht zur Geburtstagsparty Ihres Freundes/Ihrer Freundin kommen.", subpoints: ["Grund für Ihre Absage", "Entschuldigung", "Geschenkvorschlag machen", "Alternativtermin vorschlagen"], hints: ["Anrede: Liebe/r ..., / Hallo ...,", "Absage: Leider kann ich nicht kommen, weil...", "Entschuldigung: Es tut mir sehr leid, dass...", "Abschluss: Viele Grüße / Liebe Grüße"]),
        WritingTask(type: .email, topic: "Beschwerde über eine Lieferung", situation: "Sie haben online einen Artikel bestellt, aber die Lieferung hat Probleme.", subpoints: ["Was haben Sie bestellt?", "Was ist das Problem mit der Lieferung?", "Was möchten Sie vom Händler?", "Bis wann erwarten Sie eine Antwort?"], hints: ["Anrede: Sehr geehrte Damen und Herren,", "Problem: Leider muss ich mich beschweren, weil...", "Forderung: Ich möchte, dass... / Ich erwarte, dass...", "Abschluss: Mit freundlichen Grüßen"]),
        WritingTask(type: .email, topic: "Terminänderung für Sprachkurs", situation: "Sie haben einen Sprachkurs gebucht, möchten aber den Termin ändern.", subpoints: ["Welchen Kurs haben Sie gebucht?", "Warum müssen Sie den Termin ändern?", "Welchen neuen Termin möchten Sie?", "Bis wann brauchen Sie eine Antwort?"], hints: ["Anrede: Sehr geehrte Damen und Herren,", "Grund: Leider kann ich am ... nicht teilnehmen, weil...", "Bitte: Könnten Sie mir einen anderen Termin anbieten?", "Abschluss: Mit freundlichen Grüßen"]),
        WritingTask(type: .email, topic: "Einladung zu einem gemeinsamen Ausflug", situation: "Sie möchten Ihre Freunde zu einem Ausflug einladen.", subpoints: ["Wohin möchten Sie fahren?", "Wann soll der Ausflug stattfinden?", "Was sollten Ihre Freunde mitbringen?", "Wie können Sie erreicht werden?"], hints: ["Anrede: Liebe/r ..., / Hallo zusammen,", "Einladung: Ich möchte euch einladen zu...", "Details: Der Ausflug findet am ... statt.", "Abschluss: Ich freue mich auf eure Antwort!"]),
        WritingTask(type: .email, topic: "Anfrage nach Informationen über eine Wohnung", situation: "Sie haben eine Wohnungsanzeige gesehen und möchten mehr Informationen.", subpoints: ["Welche Wohnung interessiert Sie?", "Fragen zur Wohnung (Größe, Preis, Lage)", "Wann könnten Sie die Wohnung besichtigen?", "Wie können Sie kontaktiert werden?"], hints: ["Anrede: Sehr geehrte Damen und Herren,", "Interesse: Ich habe Ihre Anzeige gelesen und interessiere mich für...", "Fragen: Ich hätte noch einige Fragen: ...", "Abschluss: Ich freue mich auf Ihre Antwort."]),
        WritingTask(type: .email, topic: "Entschuldigung für Verspätung", situation: "Sie kommen zu einem wichtigen Termin zu spät und schreiben eine E-Mail.", subpoints: ["Für welchen Termin entschuldigen Sie sich?", "Was war der Grund für die Verspätung?", "Wie entschuldigen Sie sich?", "Was schlagen Sie vor?"], hints: ["Anrede: Sehr geehrte/r ..., / Liebe/r ...,", "Entschuldigung: Es tut mir sehr leid, dass...", "Grund: Leider hatte ich... / Der Grund war...", "Vorschlag: Können wir einen neuen Termin vereinbaren?"]),
        WritingTask(type: .email, topic: "Bitte um Urlaubstage", situation: "Sie möchten bei Ihrem Chef/Ihrer Chefin Urlaub beantragen.", subpoints: ["Wann möchten Sie Urlaub nehmen?", "Wie lange möchten Sie frei haben?", "Was ist der Grund für Ihren Urlaub?", "Wer kann Sie während des Urlaubs vertreten?"], hints: ["Anrede: Sehr geehrte/r Frau/Herr ...,", "Antrag: Ich möchte gerne vom ... bis ... Urlaub nehmen.", "Grund: Der Grund ist... / Ich möchte...", "Vertretung: Meine Aufgaben kann ... übernehmen."]),
        WritingTask(type: .email, topic: "Anfrage für einen Arzttermin", situation: "Sie brauchen einen Termin beim Arzt und schreiben eine E-Mail.", subpoints: ["Warum brauchen Sie einen Termin?", "Wann hätten Sie Zeit?", "Sind Sie Patient/Patientin in dieser Praxis?", "Wie sind Ihre Kontaktdaten?"], hints: ["Anrede: Sehr geehrte Damen und Herren,", "Terminwunsch: Ich möchte gerne einen Termin bei... vereinbaren.", "Zeitvorschlag: Ich hätte am ... oder am ... Zeit.", "Abschluss: Vielen Dank im Voraus."]),
        WritingTask(type: .email, topic: "Antwort auf eine Einladung (Zusage)", situation: "Sie wurden zu einer Hochzeit eingeladen und möchten zusagen.", subpoints: ["Bedanken Sie sich für die Einladung", "Sagen Sie zu, dass Sie kommen", "Fragen Sie nach Details (Dresscode, Geschenkwünsche)", "Sagen Sie, wie Sie sich freuen"], hints: ["Anrede: Liebe/r ...,", "Dank: Vielen Dank für die Einladung zu eurer Hochzeit!", "Zusage: Ich komme sehr gerne!", "Abschluss: Ich freue mich sehr auf den Tag!"]),
        WritingTask(type: .email, topic: "Reklamation im Restaurant", situation: "Sie waren in einem Restaurant und waren mit dem Essen nicht zufrieden.", subpoints: ["Wann waren Sie im Restaurant?", "Was war das Problem mit dem Essen?", "Wie haben Sie sich gefühlt?", "Was erwarten Sie vom Restaurant?"], hints: ["Anrede: Sehr geehrte Damen und Herren,", "Problem: Leider war ich mit... nicht zufrieden.", "Beschreibung: Das Essen war... / Der Service war...", "Erwartung: Ich möchte, dass..."]),
        WritingTask(type: .email, topic: "Anfrage nach einem Job", situation: "Sie haben eine Stellenanzeige gesehen und möchten sich bewerben.", subpoints: ["Für welche Stelle interessieren Sie sich?", "Warum sind Sie für die Stelle geeignet?", "Wann könnten Sie anfangen?", "Welche Unterlagen schicken Sie?"], hints: ["Anrede: Sehr geehrte Damen und Herren,", "Interesse: Ich bewerbe mich für die Stelle als...", "Qualifikation: Ich habe Erfahrung in... / Ich kann...", "Abschluss: Über eine Einladung zum Gespräch würde ich mich freuen."]),
        WritingTask(type: .email, topic: "Absage eines Abonnements", situation: "Sie möchten ein Zeitschriften-Abonnement kündigen.", subpoints: ["Welches Abonnement möchten Sie kündigen?", "Seit wann haben Sie das Abonnement?", "Warum möchten Sie kündigen?", "Zum welchen Datum soll die Kündigung wirksam sein?"], hints: ["Anrede: Sehr geehrte Damen und Herren,", "Kündigung: Hiermit kündige ich mein Abonnement für...", "Grund: Der Grund ist... / Ich möchte kündigen, weil...", "Datum: Die Kündigung soll zum ... wirksam werden."]),
        WritingTask(type: .email, topic: "Bitte um Hilfe beim Umzug", situation: "Sie ziehen um und bitten Freunde um Hilfe.", subpoints: ["Wann ziehen Sie um?", "Was brauchen Sie für Hilfe?", "Was bieten Sie Ihren Helfern an?", "Bis wann brauchen Sie eine Antwort?"], hints: ["Anrede: Liebe/r ..., / Hallo ...,", "Bitte: Ich ziehe um und brauche eure Hilfe!", "Details: Der Umzug ist am ... / Ich brauche Hilfe beim...", "Angebot: Natürlich gibt es danach Pizza und Getränke!"]),
        WritingTask(type: .email, topic: "Anfrage nach Öffnungszeiten", situation: "Sie möchten ein Museum besuchen und fragen nach Informationen.", subpoints: ["Welches Museum möchten Sie besuchen?", "Wann möchten Sie kommen?", "Fragen zu Öffnungszeiten und Eintrittspreisen", "Gibt es Ermäßigungen für Gruppen?"], hints: ["Anrede: Sehr geehrte Damen und Herren,", "Interesse: Ich möchte gerne Ihr Museum besuchen.", "Fragen: Könnten Sie mir bitte folgende Informationen geben: ...", "Abschluss: Vielen Dank für Ihre Hilfe."]),
        WritingTask(type: .email, topic: "Danksagung nach Hilfe", situation: "Ein Freund/Eine Freundin hat Ihnen bei einem Problem geholfen.", subpoints: ["Wofür möchten Sie sich bedanken?", "Wie hat die Person Ihnen geholfen?", "Wie wichtig war diese Hilfe für Sie?", "Was möchten Sie der Person anbieten (Einladung, Gegenleistung)?"], hints: ["Anrede: Liebe/r ...,", "Dank: Ich möchte mich herzlich bedanken für...", "Bedeutung: Deine Hilfe war sehr wichtig, weil...", "Einladung: Darf ich dich zum Essen einladen?"])
    ]
}
