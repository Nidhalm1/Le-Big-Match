#!/usr/bin/env python3
"""
make_csv.py – Le Big Match
──────────────────────────
Génère des fichiers CSV conformes au **schéma Postgres** fourni

Exécution :
    pip install faker python-slugify
    python make_csv.py
"""

import csv
import datetime
import json
import random
import uuid
from pathlib import Path

from faker import Faker
from slugify import slugify

fake = Faker("fr_FR")
Path("CSV").mkdir(exist_ok=True)

# ────────────────────────────────────────────────────────────
# PARAMÈTRAGE
# ────────────────────────────────────────────────────────────
N_USERS      = 120
N_PLACES     = 25
N_EVENTS     = 40
N_TAGS       = 10
N_NOTIF      = 60

# Valeurs exactes de l'ENUM provider_value
PROVIDERS = [
    "facebook",
    "instagram",
    "x",
    "linkedin",
    "ticketmaster",
    "snapchat",
    "tiktok",
]
# Parmi ces providers, seuls deux génèrent des événements IRL dans ce script
EVENT_PROVIDERS = ["facebook", "ticketmaster"]

# ────────────────────────────────────────────────────────────
# FONCTIONS UTILITAIRES
# ────────────────────────────────────────────────────────────

def rand_ts_this_year() -> str:
    return fake.date_time_this_year().strftime("%Y-%m-%d %H:%M:%S")

def iso_now(days_offset: int = 0) -> str:
    return (
        datetime.datetime.now() + datetime.timedelta(days=days_offset)
    ).strftime("%Y-%m-%d %H:%M:%S")

def gen_external_uid(provider: str) -> str:
    """Retourne un identifiant externe réaliste selon la plateforme."""
    if provider == "facebook":
        return str(random.randint(10**11, 10**12 - 1))  # 12 chiffres
    if provider in {"instagram", "x", "tiktok"}:
        return slugify(fake.user_name()[:15])
    if provider == "linkedin":
        return "urn:li:person:" + uuid.uuid4().hex[:22]
    if provider == "ticketmaster":
        return str(random.randint(10**9, 10**10 - 1))  # 10 chiffres
    if provider == "snapchat":
        return "".join(random.choices("abcdefghijklmnopqrstuvwxyz", k=8))
    return slugify(fake.user_name())

# ────────────────────────────────────────────────────────────
# 1. USERS
# ────────────────────────────────────────────────────────────
users_ids = list(range(1, N_USERS + 1))
with open("CSV/user.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(
        [
            "pseudo",
            "email",
            "height_cm",
            "weight_kg",
            "eye_color",
            "city",
            "country",
            "gender",
            "orientation",
            "birthday",
        ]
    )
    for i in users_ids:
        w.writerow(
            [
                slugify(fake.user_name() + str(i)),
                fake.unique.email(),
                random.randint(150, 200),
                round(random.uniform(50, 100), 1),
                random.choice(["blue", "brown", "green", "hazel"]),
                fake.city(),
                fake.current_country(),
                random.choice(["man", "woman"]),
                random.choice(["heterosexual", "other"]),
                fake.date_of_birth(minimum_age=18, maximum_age=55),
            ]
        )

# ────────────────────────────────────────────────────────────
# 2. PLACES
# ────────────────────────────────────────────────────────────
places_ids = list(range(1, N_PLACES + 1))
with open("CSV/place.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["name", "address", "city", "country"])
    for _ in places_ids:
        w.writerow(
            [
                fake.company() + " " + random.choice(["Bar", "Club", "Gym", "Hall"]),
                fake.address().replace("\n", " "),
                fake.city(),
                fake.current_country(),
            ]
        )

# ────────────────────────────────────────────────────────────
# 3. TAGS & CATÉGORIES
# ────────────────────────────────────────────────────────────
tags = [
    "cycling",
    "rock",
    "cinema",
    "hiking",
    "yoga",
    "coding",
    "coffee",
    "art",
    "boardgames",
    "running",
]
with open("CSV/tag.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["type"])
    w.writerows([[t] for t in tags])

with open("CSV/category.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["name", "parent_id"])
    w.writerows([
        ["Sport", ""],  # id 1
        ["Culture", ""],  # id 2
        ["Endurance", 1],  # id 3
        ["Musique", 2],  # id 4
        ["Gaming", 2],  # id 5
        ["Bien-être", 1],  # id 6
    ])

with open("CSV/tag_category.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["tag_id", "category_id"])
    for tag_id in range(1, N_TAGS + 1):
        w.writerow([tag_id, random.choice([3, 4, 5, 6])])

# ────────────────────────────────────────────────────────────
# 4. EVENTS
# ────────────────────────────────────────────────────────────
now = datetime.datetime.now()
events_ids = list(range(1, N_EVENTS + 1))
event_templates = [
    "Participez à une soirée {subject} animée avec des passionnés et profitez d'une ambiance conviviale.",
    "Rejoignez-nous pour un {event_type} dédié à {subject}, idéal pour rencontrer de nouvelles personnes partageant vos intérêts.",
    "Découvrez les secrets de {subject} lors de ce {event_type} interactif, ouvert à tous les niveaux.",
    "Venez vivre une expérience unique autour de {subject} lors de notre prochain {event_type}.",
    "Un {event_type} exceptionnel sur le thème de {subject}, avec des intervenants de qualité et des surprises.",
    "Plongez dans l'univers de {subject} grâce à ce {event_type} original et enrichissant.",
    "Échangez, apprenez et amusez-vous lors de ce {event_type} consacré à {subject}.",
    "Une occasion parfaite pour approfondir vos connaissances en {subject} lors de ce {event_type}.",
    "Ne manquez pas ce {event_type} incontournable pour tous les amateurs de {subject}.",
    "Venez partager votre passion pour {subject} lors de ce {event_type} convivial et inspirant.",
    "Initiez-vous à {subject} lors de ce {event_type} encadré par des experts reconnus.",
    "Un {event_type} immersif pour explorer toutes les facettes de {subject}.",
    "Profitez d'ateliers pratiques sur {subject} dans une ambiance détendue.",
    "Ce {event_type} vous permettra de rencontrer des professionnels du domaine {subject}.",
    "Développez vos compétences en {subject} grâce à ce {event_type} interactif.",
    "Un {event_type} festif autour de {subject}, avec animations et dégustations.",
    "Participez à des discussions passionnantes sur {subject} lors de ce {event_type}.",
    "Un {event_type} pour petits et grands, centré sur la découverte de {subject}.",
    "Venez relever des défis autour de {subject} lors de ce {event_type} compétitif.",
    "Un {event_type} collaboratif pour créer ensemble autour de {subject}.",
    "Découvrez les dernières tendances en {subject} lors de ce {event_type} innovant.",
    "Un {event_type} exclusif réservé aux passionnés de {subject}.",
    "Rencontrez des influenceurs de {subject} lors de ce {event_type} unique.",
    "Un {event_type} pour échanger vos astuces et expériences sur {subject}.",
    "Vivez une aventure inoubliable autour de {subject} lors de ce {event_type}.",
]
event_types = [
    "Soirée", "Concert", "Atelier", "Conférence", "Projection", "Tournoi", "Rencontre", "Exposition", "Festival", "Cours", "Spectacle", "Workshop", "Séminaire", "Vernissage", "Compétition", "Bal", "Gala", "Dégustation", "Projection", "Meetup"
]
event_subjects = [
    "Jazz", "Startup", "Peinture", "Cinéma", "Coding", "Danse", "Photographie", "Théâtre", "Musique", "Littérature", "Cuisine", "Fitness", "Jeux", "Science", "Technologie", "Vin", "Lecture", "Nature", "Sport", "Innovation"
]
with open("CSV/event.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(
        [
            "title",
            "description",
            "tag_id",
            "starts_at",
            "ends_at",
            "price",
            "place_id",
            "organiser_id",
            "source",
        ]
    )
    for i in events_ids:
        event_type = random.choice(event_types)
        subject = random.choice(event_subjects)
        title = f"{event_type} {subject}"
        template = random.choice(event_templates)
        description = template.format(event_type=event_type, subject=subject)
        start = now + datetime.timedelta(days=random.randint(1, 60), hours=random.randint(8, 20))
        end = start + datetime.timedelta(hours=random.randint(2, 6))
        w.writerow(
            [
                title,
                description,
                random.randint(1, N_TAGS),
                start.strftime("%Y-%m-%d %H:%M:%S"),
                end.strftime("%Y-%m-%d %H:%M:%S"),
                round(random.uniform(0, 40), 2),
                random.choice(places_ids),
                random.choice(users_ids),
                random.choice(EVENT_PROVIDERS),
            ]
        )

# ────────────────────────────────────────────────────────────
# 5. SUBSCRIPTIONS
# ────────────────────────────────────────────────────────────
with open("CSV/subscription.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["user_id", "start_date", "end_date"])
    for uid in random.sample(users_ids, k=N_USERS // 2):
        start = fake.date_between(start_date="-2y", end_date="-1d")
        end = None if random.random() < 0.3 else fake.date_between(start, "+6M")
        w.writerow([uid, start, end or ""])  # chaîne vide = NULL pour COPY

# ────────────────────────────────────────────────────────────
# 6. SOCIAL ACCOUNTS
# ────────────────────────────────────────────────────────────
soc_acc_ids = []  # pour relier digital_trace.sa_id
with open("CSV/social_account.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["user_id", "provider", "external_uid"])
    acc_id = 1
    for uid in users_ids:
        for provider in random.sample(PROVIDERS, k=random.randint(1, len(PROVIDERS))):
            w.writerow([uid, provider, gen_external_uid(provider)])
            soc_acc_ids.append(acc_id)
            acc_id += 1

# ────────────────────────────────────────────────────────────
# 7. DIGITAL TRACES
# ────────────────────────────────────────────────────────────
with open("CSV/digital_trace.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["sa_id", "trace_type", "ts", "payload"])
    trace_types = ["activity", "like", "post", "comment", "share", "reaction"]
    for _ in range(200):
        sa_id = random.choice(soc_acc_ids)
        trace_type = random.choice(trace_types)
        if trace_type == "activity":
            payload = {
                "action": random.choice(["login", "logout", "profile_update", "browse"]),
                "device": random.choice(["mobile", "desktop", "tablet"]),
                "ip": fake.ipv4()
            }
        elif trace_type == "like":
            payload = {
                "target_type": random.choice(["post", "comment", "photo"]),
                "target_id": random.randint(1000, 9999)
            }
        elif trace_type == "post":
            payload = {
                "content": fake.sentence(),
                "media": random.choice(["", fake.image_url()])
            }
        elif trace_type == "comment":
            payload = {
                "comment": fake.sentence(),
                "post_id": random.randint(1000, 9999)
            }
        elif trace_type == "share":
            payload = {
                "shared_type": random.choice(["event", "post", "profile"]),
                "shared_id": random.randint(1000, 9999)
            }
        elif trace_type == "reaction":
            payload = {
                "reaction": random.choice(["like", "love", "haha", "wow", "sad", "angry"]),
                "target_id": random.randint(1000, 9999)
            }
        else:
            payload = {"info": fake.word()}
        w.writerow(
            [
                sa_id,
                trace_type,
                rand_ts_this_year(),
                json.dumps(payload),
            ]
        )

# ────────────────────────────────────────────────────────────
# 9. PARTICIPATION
# ────────────────────────────────────────────────────────────
with open("CSV/participation.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f)
    w.writerow(["user_id", "event_id", "status", "created_at"])
    for _ in range(180):
        w.writerow([
            random.choice(users_ids),
            random.choice(events_ids),
            random.choice(["interested", "going"]),
            rand_ts_this_year(),
        ])

# ───────── 10a. TAG_EVENT_ASSIGNMENT ──────────
with open("CSV/tag_event_assignment.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f); w.writerow(["tag_id", "event_id"])
    for ev in events_ids:
        w.writerow([random.randint(1, N_TAGS), ev])

# ───────── 10b. TAG_PLACE_ASSIGNMENT ──────────
with open("CSV/tag_place_assignment.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f); w.writerow(["tag_id", "place_id"])
    for pl in random.sample(places_ids, 10):
        w.writerow([random.randint(1, N_TAGS), pl])

# ───────── 10c. TAG_USER_ASSIGNMENT ──────────
with open("CSV/tag_user_assignment.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f); w.writerow(["tag_id", "user_id"])
    for uid in random.sample(users_ids, 50):
        w.writerow([random.randint(1, N_TAGS), uid])

# ────────────────────────────────────────────────────────────
# 11. NOTIFICATIONS
# ────────────────────────────────────────────────────────────
#!/usr/bin/env python3
"""
make_csv.py – v2
────────────────
• Corrige la casse de l'énum `provider_value` ("X" majuscule)
• Génère des `canceled_at` **seulement** pour les likes dont le `source_user_id`
  possède un abonnement actif à la date d’annulation (respecte le trigger métier)
• Reste strictement conforme à toutes tes contraintes SQL

Exécution :
    python make_csv.py
Dossier `CSV/` rempli → importer ensuite avec `load.sql`.
"""
import csv, datetime, json, random, uuid
from pathlib import Path
from faker import Faker
from slugify import slugify

fake = Faker("fr_FR")
Path("CSV").mkdir(exist_ok=True)

# ───────── PARAMETRES GLOBAUX ──────────
N_USERS, N_PLACES, N_EVENTS = 120, 25, 40
N_TAGS, N_NOTIF = 10, 60

PROVIDERS = [
    "facebook",
    "instagram",
    "X",            # casse exacte de l'ENUM
    "linkedin",
    "ticketmaster",
    "snapchat",
    "tiktok",
]
EVENT_PROVIDERS = ["facebook", "ticketmaster"]

# ───────── HELPERS ──────────
fake_date  = lambda a,b: fake.date_between(a,b)
iso        = lambda dt: dt.strftime("%Y-%m-%d %H:%M:%S")
now        = datetime.datetime.now()
rand_ts    = lambda: iso(fake.date_time_this_year())
iso_now    = lambda d=0: iso(now + datetime.timedelta(days=d))

def gen_external_uid(p):
    if p == "facebook":      return str(random.randint(10**11, 10**12-1))
    if p in {"instagram", "X", "tiktok"}: return slugify(fake.user_name()[:15])
    if p == "linkedin":      return "urn:li:person:"+uuid.uuid4().hex[:22]
    if p == "ticketmaster":  return str(random.randint(10**9, 10**10-1))
    if p == "snapchat":      return "".join(random.choices("abcdefghijklmnopqrstuvwxyz", k=8))
    return slugify(fake.user_name())

# ───────── 1. USERS ──────────
users = list(range(1, N_USERS+1))
with open("CSV/user.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["pseudo","email","height_cm","weight_kg","eye_color","city","country","gender","orientation","birthday"])
    for i in users:
        w.writerow([
            slugify(fake.user_name()+str(i)), fake.unique.email(),
            random.randint(150,200), round(random.uniform(50,100),1),
            random.choice(["blue","brown","green","hazel"]),
            fake.city(), fake.current_country(),
            random.choice(["man","woman"]), random.choice(["heterosexual","other"]),
            fake.date_of_birth(minimum_age=18, maximum_age=55)
        ])

# ───────── 2. PLACES ──────────
places = list(range(1, N_PLACES+1))
with open("CSV/place.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["name","address","city","country"])
    for _ in places:
        w.writerow([
            fake.company()+" "+random.choice(["Bar","Club","Gym","Hall"]),
            fake.address().replace("\n"," "), fake.city(), fake.current_country()
        ])

# ───────── 3. TAGS & CATEGORIES ──────────
tags=["cycling","rock","cinema","hiking","yoga","coding","coffee","art","boardgames","running"]
with open("CSV/tag.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["type"]); w.writerows([[t] for t in tags])

with open("CSV/category.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["name","parent_id"])
    w.writerows([["Sport",""],["Culture",""]])
    w.writerows([["Endurance",1],["Musique",2],["Gaming",2],["Bien-être",1]])

with open("CSV/tag_category.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["tag_id","category_id"])
    for tid in range(1,N_TAGS+1): w.writerow([tid, random.choice([3,4,5,6])])

# ───────── 4. EVENTS ──────────
events=list(range(1,N_EVENTS+1))
with open("CSV/event.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["title","description","tag_id","starts_at","ends_at","price","place_id","organiser_id","source"])
    for ev in events:
        start=now+datetime.timedelta(days=random.randint(1,60),hours=random.randint(8,20))
        w.writerow([f"Event #{ev}",fake.sentence(10),random.randint(1,N_TAGS),iso(start),iso(start+datetime.timedelta(hours=random.randint(2,6))),round(random.uniform(0,40),2),random.choice(places),random.choice(users),random.choice(EVENT_PROVIDERS)])

# ───────── 5. SUBSCRIPTIONS ──────────
subscriptions=[]
with open("CSV/subscription.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["user_id","start_date","end_date"])
    for uid in random.sample(users,k=N_USERS//2):
        start=fake_date("-2y","-1d"); end=None if random.random()<0.3 else fake_date(start,"+6M")
        w.writerow([uid,start,end or ""]); subscriptions.append((uid,start,end))

# helper pour likes annulés
def has_active_sub(uid, ts):
    for s,e in [(s[1],s[2]) for s in subscriptions if s[0]==uid]:
        if s<=ts.date() and (e=="" or e is None or ts.date()<=e):
            return True
    return False

# ───────── 6. SOCIAL_ACCOUNT ──────────
sa_ids=[]
with open("CSV/social_account.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["user_id","provider","external_uid"])
    acc=1
    for uid in users:
        for prov in random.sample(PROVIDERS,k=random.randint(1,len(PROVIDERS))):
            w.writerow([uid,prov,gen_external_uid(prov)]); sa_ids.append(acc); acc+=1

# ───────── 7. DIGITAL_TRACE ──────────
with open("CSV/digital_trace.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["sa_id","trace_type","ts","payload"])
    for _ in range(200):
        w.writerow([random.choice(sa_ids),random.choice(["activity","like","post"]),rand_ts(),json.dumps({"info":fake.word()})])

# ───────── 8. LIKES (respect du trigger "annulation = abonnés") ──────────
with open("CSV/likes.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["source_user_id","target_user_id","value","created_at","canceled_at"])
    for _ in range(400):
        src,tgt=random.sample(users,2); value=random.choice(["like","nope"])
        cancel=""
        if value=="nope" and random.random()<0.2:
            ts=datetime.datetime.strptime(rand_ts(),"%Y-%m-%d %H:%M:%S")
            if has_active_sub(src,ts): cancel=iso(ts)
        w.writerow([src,tgt,value,rand_ts(),cancel])

# ───────── 9. PARTICIPATION ──────────
with open("CSV/participation.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["user_id","event_id","status","created_at"])
    for _ in range(180):
        w.writerow([random.choice(users),random.choice(events),random.choice(["interested","going"]),rand_ts()])

# ───────── 10a. TAG_EVENT_ASSIGNMENT ──────────
with open("CSV/tag_event_assignment.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f); w.writerow(["tag_id", "event_id"])
    for ev in events:
        w.writerow([random.randint(1, N_TAGS), ev])

# ───────── 10b. TAG_PLACE_ASSIGNMENT ──────────
with open("CSV/tag_place_assignment.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f); w.writerow(["tag_id", "place_id"])
    for pl in random.sample(places, 10):
        w.writerow([random.randint(1, N_TAGS), pl])

# ───────── 10c. TAG_USER_ASSIGNMENT ──────────
with open("CSV/tag_user_assignment.csv", "w", newline="", encoding="utf8") as f:
    w = csv.writer(f); w.writerow(["tag_id", "user_id"])
    for uid in random.sample(users, 50):
        w.writerow([random.randint(1, N_TAGS), uid])

# ───────── 11. NOTIFICATION ──────────
notif_templates=[
    "Votre inscription à l'événement {event} a bien été prise en compte.",
    "N'oubliez pas : l'événement {event} commence bientôt !",
    "Vous avez reçu un nouveau like de la part d'un utilisateur.",
    "Votre abonnement a été renouvelé avec succès.",
    "Un nouvel événement {event} a été ajouté près de chez vous.",
    "Vous avez été ajouté à la liste d'attente pour l'événement {event}.",
    "Votre participation à l'événement {event} a été confirmée.",
    "L'événement {event} a été annulé. Nous vous tiendrons informé.",
    "Un utilisateur souhaite se connecter avec vous.",
    "Votre profil a été mis à jour avec succès.",
    "Vous avez un nouveau message concernant {event}.",
    "Votre demande d'ami a été acceptée.",
    "Votre ticket pour {event} est disponible dans votre espace.",
    "Un rappel : {event} commence dans 1 heure.",
    "Vous avez été mentionné dans une discussion liée à {event}.",
    "Votre réservation pour {event} a été annulée à votre demande.",
    "Un utilisateur a commenté votre participation à {event}.",
    "Votre note pour {event} a bien été enregistrée.",
    "Un événement similaire à {event} pourrait vous intéresser.",
    "Votre présence à {event} a été remarquée par l'organisateur.",
]
with open("CSV/notification.csv","w",newline="",encoding="utf8") as f:
    w=csv.writer(f); w.writerow(["user_id","message","sent_at"])
    for _ in range(N_NOTIF):
        event_name=f"Event #{random.choice(events)}"
        msg=random.choice(notif_templates).format(event=event_name)
        w.writerow([random.choice(users),msg,rand_ts()])

print("✅ CSV générés (v2) → dossier CSV/")
