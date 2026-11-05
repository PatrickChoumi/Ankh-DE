// Galerie des contrôles d'Ankh DE : une fenêtre qui montre chaque contrôle,
// pour les captures « avant / après » et pour les mesures du banc (DE-007).
//
// Elle ne dépend que de Qt Widgets : elle tourne donc sans Plasma, sous Xvfb,
// dans un conteneur. C'est ce qui permet de mesurer le style sans VM.
//
//   galerie --mesures <fichier.json>   écrit les tailles que le style donne
//   galerie --titre "Ankh DE"          titre de la fenêtre
//
// Le style se choisit par -style (argument standard de Qt), et les couleurs
// par le kdeglobals de l'environnement (KColorScheme), comme dans une vraie
// session.
#include <initializer_list>

#include <QApplication>
#include <QCheckBox>
#include <QComboBox>
#include <QFile>
#include <QFontDatabase>
#include <QFormLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QProgressBar>
#include <QPushButton>
#include <QRadioButton>
#include <QScrollBar>
#include <QSlider>
#include <QSpinBox>
#include <QStyle>
#include <QStyleOptionProgressBar>
#include <QTabWidget>
#include <QTextStream>
#include <QToolButton>
#include <QTimer>
#include <QVBoxLayout>

#include <KColorScheme>
#include <KConfigGroup>
#include <KSharedConfig>

namespace
{

// QProgressBar::initStyleOption est protégée, et c'est elle qui pose
// State_Horizontal. Sans ce drapeau, le style croit la barre verticale et
// centre sur la largeur : on mesurait 25 px (la hauteur du widget) au lieu
// des 3 px de la barre dessinée. On passe donc par la vraie option.
class BarreMesurable : public QProgressBar
{
public:
    using QProgressBar::QProgressBar;

    int hauteurDeLaBarreDessinee() const
    {
        QStyleOptionProgressBar opt;
        initStyleOption(&opt);
        opt.rect = QRect(QPoint(0, 0), sizeHint());
        return style()->subElementRect(QStyle::SE_ProgressBarGroove, &opt, this).height();
    }
};

QGroupBox *boite(const QString &titre, QLayout *contenu)
{
    auto *b = new QGroupBox(titre);
    b->setLayout(contenu);
    return b;
}

} // namespace

int main(int argc, char **argv)
{
    QApplication app(argc, argv);

    // Un QApplication nu ne lit PAS kdeglobals : ni ses couleurs, ni ses
    // polices. Dans une vraie session, c'est plasma-integration (le greffon
    // de thème de plateforme) qui s'en charge. Au banc, on le fait
    // explicitement, pour que la mesure ne dépende pas de la présence de
    // Plasma dans le conteneur — et pour qu'elle soit reproductible.
    // Relevé le 2026-11-05 : sans cela, la capture « sombre » et la capture
    // « claire » étaient le même gris 239,239,239, celui de Qt par défaut.
    {
        const KSharedConfigPtr config = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
        QApplication::setPalette(KColorScheme::createApplicationPalette(config));

        const KConfigGroup general(config, QStringLiteral("General"));
        const QString demande = general.readEntry("font", QString());
        QFont police;
        if (!demande.isEmpty() && police.fromString(demande)) {
            QApplication::setFont(police);
        } else if (!demande.isEmpty()) {
            qWarning("Police illisible dans kdeglobals : %s", qPrintable(demande));
            return 2;
        }
    }

    QString fichierMesures;
    QString fichierCapture;
    QString titre = QStringLiteral("Galerie des contrôles");
    const QStringList args = app.arguments();
    for (int i = 1; i < args.size() - 1; ++i) {
        if (args.at(i) == QLatin1String("--mesures")) {
            fichierMesures = args.at(i + 1);
        } else if (args.at(i) == QLatin1String("--capture")) {
            fichierCapture = args.at(i + 1);
        } else if (args.at(i) == QLatin1String("--titre")) {
            titre = args.at(i + 1);
        }
    }

    auto *fenetre = new QWidget;
    fenetre->setWindowTitle(titre);
    auto *racine = new QVBoxLayout(fenetre);
    racine->setContentsMargins(24, 24, 24, 24); // marge de dialogue de WinUI
    racine->setSpacing(16);

    // --- Boutons ---------------------------------------------------------
    auto *lBoutons = new QHBoxLayout;
    auto *bDefaut = new QPushButton(QStringLiteral("Bouton principal"));
    bDefaut->setDefault(true);
    auto *bNormal = new QPushButton(QStringLiteral("Bouton"));
    auto *bPlat = new QPushButton(QStringLiteral("Plat"));
    bPlat->setFlat(true);
    auto *bInactif = new QPushButton(QStringLiteral("Désactivé"));
    bInactif->setEnabled(false);
    auto *bOutil = new QToolButton;
    bOutil->setText(QStringLiteral("⋯"));
    // Le type de la liste doit être explicite : sans cela, le compilateur
    // essaie de déduire un seul type et butte sur QPushButton* vs QWidget*.
    for (QWidget *w : std::initializer_list<QWidget *>{bDefaut, bNormal, bPlat, bInactif, bOutil}) {
        lBoutons->addWidget(w);
    }
    lBoutons->addStretch();

    // --- Champs ----------------------------------------------------------
    auto *lChamps = new QFormLayout;
    lChamps->setSpacing(12);
    auto *champ = new QLineEdit(QStringLiteral("Texte saisi"));
    auto *liste = new QComboBox;
    liste->addItems({QStringLiteral("Sombre"), QStringLiteral("Clair"), QStringLiteral("Automatique")});
    auto *compteur = new QSpinBox;
    compteur->setValue(48);
    compteur->setSuffix(QStringLiteral(" px"));
    lChamps->addRow(QStringLiteral("Champ de texte"), champ);
    lChamps->addRow(QStringLiteral("Liste déroulante"), liste);
    lChamps->addRow(QStringLiteral("Compteur"), compteur);

    // --- Sélection -------------------------------------------------------
    auto *lSelection = new QVBoxLayout;
    lSelection->setSpacing(8);
    auto *caseCochee = new QCheckBox(QStringLiteral("Case cochée"));
    caseCochee->setChecked(true);
    auto *caseVide = new QCheckBox(QStringLiteral("Case vide"));
    auto *caseTriple = new QCheckBox(QStringLiteral("Partiellement cochée"));
    caseTriple->setTristate(true);
    caseTriple->setCheckState(Qt::PartiallyChecked);
    auto *radioA = new QRadioButton(QStringLiteral("Bouton radio choisi"));
    radioA->setChecked(true);
    auto *radioB = new QRadioButton(QStringLiteral("Bouton radio"));
    for (QWidget *w : std::initializer_list<QWidget *>{caseCochee, caseVide, caseTriple, radioA, radioB}) {
        lSelection->addWidget(w);
    }

    // --- Curseurs et progression -----------------------------------------
    auto *lGlisse = new QVBoxLayout;
    lGlisse->setSpacing(12);
    auto *curseur = new QSlider(Qt::Horizontal);
    curseur->setValue(60);
    auto *progression = new BarreMesurable;
    progression->setValue(45);
    auto *defilement = new QScrollBar(Qt::Horizontal);
    defilement->setValue(30);
    lGlisse->addWidget(curseur);
    lGlisse->addWidget(progression);
    lGlisse->addWidget(defilement);

    // --- Liste et onglets ------------------------------------------------
    auto *elements = new QListWidget;
    elements->addItems({QStringLiteral("Élément choisi"),
                        QStringLiteral("Deuxième élément"),
                        QStringLiteral("Troisième élément"),
                        QStringLiteral("Quatrième élément")});
    elements->setCurrentRow(0);
    // Assez haut pour quatre éléments même à 40 px (la hauteur de
    // Windows 11) : sinon la planche « avant / après » semble comparer
    // des contenus différents.
    elements->setMinimumHeight(4 * 40 + 12);

    auto *onglets = new QTabWidget;
    onglets->addTab(elements, QStringLiteral("Liste"));
    auto *page = new QLabel(QStringLiteral("Deuxième page"));
    page->setAlignment(Qt::AlignCenter);
    onglets->addTab(page, QStringLiteral("Autre"));

    // --- Assemblage ------------------------------------------------------
    auto *haut = new QHBoxLayout;
    haut->setSpacing(16);
    haut->addWidget(boite(QStringLiteral("Champs"), lChamps), 1);
    haut->addWidget(boite(QStringLiteral("Sélection"), lSelection), 1);

    racine->addWidget(boite(QStringLiteral("Boutons"), lBoutons));
    racine->addLayout(haut);
    racine->addWidget(boite(QStringLiteral("Curseurs et progression"), lGlisse));
    racine->addWidget(onglets, 1);

    fenetre->resize(720, 620);
    fenetre->show();

    // --- Mesures ---------------------------------------------------------
    // On relève ce que le STYLE impose, pas ce que la disposition a étiré :
    // sizeHint pour les contrôles, et l'épaisseur pour les barres.
    if (!fichierMesures.isEmpty()) {
        const QFont police = champ->font();

        const int grooveProgression = progression->hauteurDeLaBarreDessinee();

        QJsonObject m{
            {QStringLiteral("police.famille"), QFontInfo(police).family()},
            {QStringLiteral("police.corps.px"), QFontInfo(police).pixelSize()},
            {QStringLiteral("controle.bouton.hauteur"), bNormal->sizeHint().height()},
            {QStringLiteral("controle.bouton_principal.hauteur"), bDefaut->sizeHint().height()},
            {QStringLiteral("controle.bouton_outil.hauteur"), bOutil->sizeHint().height()},
            {QStringLiteral("controle.champ.hauteur"), champ->sizeHint().height()},
            {QStringLiteral("controle.liste_deroulante.hauteur"), liste->sizeHint().height()},
            {QStringLiteral("controle.compteur.hauteur"), compteur->sizeHint().height()},
            {QStringLiteral("controle.case.hauteur"), caseCochee->sizeHint().height()},
            {QStringLiteral("controle.case.taille"),
             app.style()->pixelMetric(QStyle::PM_IndicatorWidth, nullptr, caseCochee)},
            {QStringLiteral("controle.radio.taille"),
             app.style()->pixelMetric(QStyle::PM_ExclusiveIndicatorWidth, nullptr, radioA)},
            // La hauteur du widget comprend le texte et ses marges (25 px) :
            // ce qui se compare à Windows 11, c'est la barre DESSINÉE, que le
            // style place par SE_ProgressBarGroove (ProgressBar_Thickness).
            {QStringLiteral("controle.progression.hauteur"), grooveProgression},
            {QStringLiteral("controle.progression.widget"), progression->sizeHint().height()},
            {QStringLiteral("controle.defilement.largeur"),
             app.style()->pixelMetric(QStyle::PM_ScrollBarExtent, nullptr, defilement)},
            {QStringLiteral("controle.curseur.poignee"),
             app.style()->pixelMetric(QStyle::PM_SliderThickness, nullptr, curseur)},
            {QStringLiteral("controle.liste.hauteur"),
             elements->visualItemRect(elements->item(0)).height()},
            {QStringLiteral("style.nom"), app.style()->name()},
            // Diagnostic : toutes les mesures de WinUI sont à 96 ppp. Si la
            // résolution dérive, les tailles en points dérivent avec elle.
            {QStringLiteral("diag.ppp"), fenetre->logicalDpiY()},
            {QStringLiteral("diag.police_demandee"), police.family()},
            {QStringLiteral("diag.police_points"), police.pointSizeF()},
        };
        QFile f(fichierMesures);
        if (f.open(QIODevice::WriteOnly)) {
            f.write(QJsonDocument(m).toJson());
        }
        QTextStream(stdout) << QJsonDocument(m).toJson(QJsonDocument::Compact) << "\n";
    }

    // --- Capture ---------------------------------------------------------
    // C'est Qt qui photographie la fenêtre, pas l'écran : l'image fait
    // exactement la taille de la fenêtre, sans le fond noir de Xvfb, et elle
    // est identique d'une exécution à l'autre. En revanche elle ne montre ni
    // la décoration (lot 2) ni l'ombre : il n'y a pas de gestionnaire de
    // fenêtres ici. Ces surfaces se mesurent en VM.
    if (!fichierCapture.isEmpty()) {
        QTimer::singleShot(400, &app, [fenetre, fichierCapture, &app] {
            if (!fenetre->grab().save(fichierCapture)) {
                qWarning("Capture impossible : %s", qPrintable(fichierCapture));
                app.exit(3);
                return;
            }
            app.quit();
        });
    }

    return app.exec();
}
