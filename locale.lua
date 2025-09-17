Locale = Locale or {}

local Translations = {
    en = {
        ['error.drill_only_zone'] = 'You can only drill for ice in this area!',
        ['error.not_in_mine'] = "You're not inside a mine!",
        ['error.already_working'] = "You're already doing something!",
        ['error.ice_drilling_unavailable'] = 'Ice drilling is not available.',
        ['error.drilling_inside_mine'] = 'You cannot drill for ice while inside a mine.',
        ['error.not_in_ice_field'] = 'You need to be at an ice field to drill.',
        ['error.need_near_drill'] = 'You need to be near a drill.',
        ['error.washing_not_configured'] = 'Washing is not configured.',
        ['error.not_in_water'] = "You're not in water!",
        ['error.washing_no_dirty_stone'] = 'You do not have a dirty stone.',
        ['washing.no_valuable_resources'] = 'No valuable resources found.',
        ['washing.received_gem'] = 'Received: %s',
        ['washing.countdown_label'] = 'Washing stone: %ds',
        ['washing.progress_label'] = 'Washing the dirty stone',
        ['mining.found_shiny_ore'] = 'You have uncovered a dirty stone!',
        ['ice_drill.target_label'] = 'Drill for ice',
        ['ice_drill.progress_label'] = 'Drilling ice',
        ['ice_drill.failure_default'] = 'The drill is not operational.',
        ['ice_drill.depleted_message'] = 'The drill has been depleted and needs repairs.',
        ['ice_drill.no_reward'] = 'No reward configured for the drill.',
        ['ice_drill.durability'] = 'Drill durability: %d/%d',
        ['pickaxe.durability'] = 'Durability: %d/%d',
        ['pickaxe.broken_message'] = 'Your pickaxe broke!',
        ['blips.lake_isabella_ice_field'] = 'Lake Isabella Ice Field',
        ['blips.spider_gorge_ice_shelf'] = 'Spider Gorge Ice Shelf',
        ['blips.grizzlies_mine'] = 'Grizzlies Mine',
        ['blips.annesburg_mine'] = 'Annesburg Mine',
        ['blips.donner_mine'] = 'Donner Mine',
        ['blips.big_valley_mine'] = 'Big Valley Mine',
        ['blips.big_valley_mine_hidden'] = 'Big Valley Mine Hidden',
        ['blips.devils_cave'] = 'Devils Cave',
        ['blips.bear_cave'] = 'Bear Cave'
    },
    pl = {
        ['error.drill_only_zone'] = 'W tym obszarze możesz wiercić tylko lód!',
        ['error.not_in_mine'] = 'Nie jesteś w kopalni!',
        ['error.already_working'] = 'Już coś robisz!',
        ['error.ice_drilling_unavailable'] = 'Wiercenie lodu jest niedostępne.',
        ['error.drilling_inside_mine'] = 'Nie możesz wiercić lodu, będąc w kopalni.',
        ['error.not_in_ice_field'] = 'Musisz być na polu lodowym, aby wiercić.',
        ['error.need_near_drill'] = 'Musisz znajdować się przy wiertle.',
        ['error.washing_not_configured'] = 'Mycie nie jest skonfigurowane.',
        ['error.not_in_water'] = 'Nie jesteś w wodzie!',
        ['error.washing_no_dirty_stone'] = 'Nie masz zabrudzonego kamienia.',
        ['washing.no_valuable_resources'] = 'Nie znaleziono żadnych cennych surowców.',
        ['washing.received_gem'] = 'Otrzymano: %s',
        ['washing.countdown_label'] = 'Mycie kamienia: %ds',
        ['washing.progress_label'] = 'Mycie zabrudzonego kamienia',
        ['mining.found_shiny_ore'] = 'Znalazłeś zabrudzony kamień!',
        ['ice_drill.target_label'] = 'Rozpocznij wiercenie lodu',
        ['ice_drill.progress_label'] = 'Wiercenie lodu',
        ['ice_drill.failure_default'] = 'Wiertło jest niesprawne.',
        ['ice_drill.depleted_message'] = 'Wiertło zostało zużyte i wymaga naprawy.',
        ['ice_drill.no_reward'] = 'Dla wiertła nie skonfigurowano nagrody.',
        ['ice_drill.durability'] = 'Wytrzymałość wiertła: %d/%d',
        ['pickaxe.durability'] = 'Wytrzymałość: %d/%d',
        ['pickaxe.broken_message'] = 'Twój kilof się złamał!',
        ['blips.lake_isabella_ice_field'] = 'Pole lodowe Lake Isabella',
        ['blips.spider_gorge_ice_shelf'] = 'Lodowiec Spider Gorge',
        ['blips.grizzlies_mine'] = 'Kopalnia w Grizzlies',
        ['blips.annesburg_mine'] = 'Kopalnia Annesburg',
        ['blips.donner_mine'] = 'Kopalnia Donner',
        ['blips.big_valley_mine'] = 'Kopalnia w Big Valley',
        ['blips.big_valley_mine_hidden'] = 'Ukryta kopalnia w Big Valley',
        ['blips.devils_cave'] = 'Jaskinia Diabła',
        ['blips.bear_cave'] = 'Jaskinia Niedźwiedzia'
    }
}

local LocaleState = {
    language = 'en',
    fallback = 'en',
    translations = Translations
}

function LocaleState:set(lang)
    if lang and self.translations[lang] then
        self.language = lang
    else
        self.language = self.fallback
    end
end

function LocaleState:t(key, ...)
    local lang = self.language or self.fallback
    local translations = self.translations
    local value = translations[lang] and translations[lang][key]

    if not value then
        value = translations[self.fallback] and translations[self.fallback][key]
    end

    if not value then
        return key
    end

    if type(value) == 'string' and select('#', ...) > 0 then
        return value:format(...)
    end

    return value
end

Locale = setmetatable(LocaleState, {
    __call = function(self, key, ...)
        return self:t(key, ...)
    end
})

Lang = Locale

return Locale
